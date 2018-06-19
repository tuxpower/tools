# Copyright 2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file
# except in compliance with the License. A copy of the License is located at
#
#     http://aws.amazon.com/apache2.0/
#
# or in the "license" file accompanying this file. This file is distributed on an "AS IS"
# BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under the License.
"""
Replace a SSH private key in a EC2 backed by a EBS volume
jose@coinfloor.co.uk
v0.1
"""
import argparse
import sys
import logging
import boto3.ec2

IMAGE_ID = 'ami-c91624b0'
INSTANCE_TYPE = 't2.micro'
MAX_COUNT=1
MIN_COUNT=1

def get_instance_block_mappings(instance_id):
    ec2 = boto3.resource(
        'ec2',
        aws_access_key_id = "AKIAJ7WL2XC7LNRE22PQ",
        aws_secret_access_key = "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")
    instance = ec2.Instance(instance_id)

    #logging.info("Block device mappings: %s", instance.block_device_mappings)
    return instance.block_device_mappings

def get_instance_root_volume(instance_id):
    ec2 = boto3.resource(
        'ec2',
        aws_access_key_id = "AKIAJ7WL2XC7LNRE22PQ",
        aws_secret_access_key = "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"
    )
    instance = ec2.Instance(instance_id)

    logging.info("Root device name: %s", instance.root_device_name)

    response = list(get_instance_block_mappings(instance_id))
    for dict in response: 
        for k, v in dict.items(): 
            if k == "DeviceName" and v == instance.root_device_name:
                volume = dict.values()[1].values()[2]

    return volume
        #print(dict.values()[0])
    #for values in dict.values(): print(values)
    #for block in response:
    #    print block

def get_worker_instance(availabilityZone, subnetId):
    client = boto3.client(
        'ec2',
        aws_access_key_id = "AKIAJ7WL2XC7LNRE22PQ",
        aws_secret_access_key = "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"
    )
    response = client.run_instances(
        ImageId=IMAGE_ID,
        InstanceType=INSTANCE_TYPE,
        MaxCount=MAX_COUNT,
        MinCount=MIN_COUNT,
        Placement={
            'AvailabilityZone': availabilityZone
        },
        SubnetId=subnetId
    )

    worker_id = response.values()[0][0].values()[11]
    ec2 = boto3.resource(
        'ec2',
        aws_access_key_id = "AKIAJ7WL2XC7LNRE22PQ",
        aws_secret_access_key = "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"
    )
    worker_instance = ec2.Instance(worker_id)
    
    filters = [{
        'Name': 'instance-id',
        'Values': [worker_id]
    }]

    logging.info("Waiting for worker instance to start: %s", worker_id)
    worker_instance.wait_until_running(Filters=filters)

    
    return worker_instance


def main(cmd_args):
    logging.info("Getting a list of block devices for instance: %s", cmd_args.instance)

    instance_root_volume = get_instance_root_volume(cmd_args.instance)
    logging.info("Root volume ID: %s", instance_root_volume)

    ec2 = boto3.resource(
        'ec2',
        aws_access_key_id = "AKIAJ7WL2XC7LNRE22PQ",
        aws_secret_access_key = "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"
    )
    instance = ec2.Instance(cmd_args.instance)


    filters = [{
        'Name': 'instance-id',
        'Values': [instance.id]
    }]

    logging.info("Stopping instance ID: %s", cmd_args.instance)
    instance.stop()
    instance.wait_until_stopped(Filters=filters)
    logging.info("Instance stoped")

    logging.info("Detaching volume ID: %s", instance_root_volume)
    instance.detach_volume(VolumeId=instance_root_volume)
    
    logging.info("Launching a new worker instance.....")
    az = instance.placement.values()[2]
    subnet = instance.subnet_id
    worker_instance = get_worker_instance(az, subnet)
    logging.info("Attaching volume to worker instance")
    worker_instance.attach_volume(
        Device='/dev/xvdz',
        VolumeId=instance_root_volume
    )



class CommandParser(argparse.ArgumentParser):
    def error(self, message):
        self.print_help()
        sys.stderr.write('error: %s\n' % message)
        sys.exit(2)

def command():
    logging.basicConfig(stream=sys.stdout, level=logging.INFO, format='%(levelname)s:%(message)s')

    parser = CommandParser(
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""description:
  Replace a SSH private key in a EC2 backed by a EBS volume

example: main.py -i instance"
  """
    )
    parser.add_argument(
        "-i", "--instance",
        dest="instance",
        help="[REQUIRED] EC2 Instance ID",
        required=True
    )

    cmd_args = parser.parse_args()

    main(cmd_args)


if __name__ == "__main__":
    command()
