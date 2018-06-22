# Replace EC2 user authorized key

A simple Python script for adding SSH pub key into a EC2 user on instances that we can't access anymore.

## Requirements

This sample project depends on `boto3`, the AWS SDK for Python, and requires
Python 2.6.5+. You can install dependencies for this project running:

    pipenv install

Pipenv is a dependency manager for Python projects. Use `pip` to install Pipenv:

    pip install --user pipenv

It's possible to spawn a new shell that ensures all commands have access to installed packages with:

    pipenv shell

## Usage

This sample script attachs a root volume from a given instance to a second instance in
the same AZ and adds a public key to a EC2 system user authorized keys file. It then
attachs that volume back to original instance and tears down the second one.

You need to make sure you're using a valid bastion host and a key to access the instance.

    pipenv run python main.py -k ~/.ssh/id_ecdsa -i 46.51.200.4 -u joseg -K ~/.ssh/id_jgaspar -I i-05951d9a5be6d6911 -U ec2-user

```script
INFO:Getting a list of block devices for instance: i-05951d9a5be6d6911
INFO:Starting new HTTPS connection (1): ec2.eu-west-1.amazonaws.com
INFO:Root volume ID: vol-0d777295993efff6d
INFO:Stopping instance ID: i-05951d9a5be6d6911
INFO:Resetting dropped connection: ec2.eu-west-1.amazonaws.com
INFO:Resetting dropped connection: ec2.eu-west-1.amazonaws.com
INFO:Resetting dropped connection: ec2.eu-west-1.amazonaws.com
INFO:Instance stoped
INFO:Detaching volume ID: vol-0d777295993efff6d
INFO:Launching a new worker instance.....
INFO:Starting new HTTPS connection (1): ec2.eu-west-1.amazonaws.com
INFO:Waiting for worker instance i-009b16fe9952317b2 to start....
INFO:Resetting dropped connection: ec2.eu-west-1.amazonaws.com
INFO:Resetting dropped connection: ec2.eu-west-1.amazonaws.com
INFO:Attaching volume to worker instance
INFO:Replacing SSH key in the volume
Warning: Permanently added '172.18.14.43' (ECDSA) to the list of known hosts.
id_ecdsa.pub                                                                                                                                                                                                                                                                                100%  191    12.6KB/s   00:00    
Shared connection to 172.18.14.43 closed.
Finished running script
INFO:Terminating worker instance
INFO:Resetting dropped connection: ec2.eu-west-1.amazonaws.com
INFO:Resetting dropped connection: ec2.eu-west-1.amazonaws.com
INFO:Resetting dropped connection: ec2.eu-west-1.amazonaws.com
INFO:Resetting dropped connection: ec2.eu-west-1.amazonaws.com
INFO:Resetting dropped connection: ec2.eu-west-1.amazonaws.com
INFO:Resetting dropped connection: ec2.eu-west-1.amazonaws.com
INFO:Worker instance terminated
INFO:Attaching volume vol-0d777295993efff6d back to original instance i-05951d9a5be6d6911
INFO:Starting back original instance i-05951d9a5be6d6911
INFO:Resetting dropped connection: ec2.eu-west-1.amazonaws.com
INFO:Instance started
```
