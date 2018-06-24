package main

import (
	"fmt"
	"os"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/ec2"
)

func main() {
	//if len(os.Args) < 2 {
	//	exitErrof("Instance ID required\nUsage: %s instance_id ...",
	//	    filepath.Base(os.Args[0]))
	//}
	instanceId := os.Args[1]

	sess := session.Must(session.NewSessionWithOptions(session.Options{
		SharedConfigState: session.SharedConfigEnable,
	}))

	ec2Svc := ec2.New(sess)

	input := &ec2.DescribeInstancesInput{
		Filters: []*ec2.Filter{
			{
				Name: aws.String("instance-id"),
				Values: []*string{
					aws.String(instanceId),
				},
			},
		},
	}

	result, err := ec2Svc.DescribeInstances(input)
	if err != nil {
		fmt.Println("Error", err)
	}

	rootDevName := *result.Reservations[0].Instances[0].RootDeviceName
	az := *result.Reservations[0].Instances[0].Placement.AvailabilityZone
	subnet := *result.Reservations[0].Instances[0].SubnetId

	inputVol := &ec2.DescribeVolumesInput{
		Filters: []*ec2.Filter{
			{
				Name: aws.String("attachment.instance-id"),
				Values: []*string{
					aws.String(instanceId),
				},
			},
			{
				Name: aws.String("attachment.device"),
				Values: []*string{
					aws.String(rootDevName),
				},
			},
		},
	}

	descResult, err := ec2Svc.DescribeVolumes(inputVol)
	if err != nil {
		fmt.Println("Error", err)
	}

	volume := *descResult.Volumes[0].VolumeId

	//fmt.Println(*descResult.Volumes[0].VolumeId)
	fmt.Println(volume)
	//var strPtr *string
	//strPtr = descResult.Volumes[0].VolumeId
	//fmt.Println(*strPtr)

	_, err = ec2Svc.StopInstances(&ec2.StopInstancesInput{
		InstanceIds: []*string{aws.String(instanceId)}})

	//inputInst := &ec2.StopInstancesInput{
	//	InstanceIds: []*string{
	//		aws.String(instanceId),
	//	},
	//}

	//_, err = ec2Svc.StopInstances(inputInst)
	if err != nil {
		fmt.Println("Error", err)
	}

	err = ec2Svc.WaitUntilInstanceStopped(input)
	if err != nil {
		fmt.Println("Error", err)
	}

	_, err = ec2Svc.DetachVolume(&ec2.DetachVolumeInput{
		VolumeId: aws.String(volume),
	})

	//inputDetVol := &ec2.DetachVolumeInput{
	//	VolumeId: []*string{
	//		aws.String(*strPtr),
	//	},
	//}

	//_, err = ec2Svc.DetachVolume(inputDetVol)
	if err != nil {
		fmt.Println("Error", err)
	}

	//placement := Placement{AvailabilityZone: az}

	runResult, err := ec2Svc.RunInstances(&ec2.RunInstancesInput{
		ImageId:      aws.String("ami-c91624b0"),
		InstanceType: aws.String("t2.micro"),
		KeyName:      aws.String("jgaspar"),
		MaxCount:     aws.Int64(1),
		MinCount:     aws.Int64(1),
		Placement:    &ec2.Placement{AvailabilityZone: aws.String(az)},
		SubnetId:     aws.String(subnet),
	})
	if err != nil {
		fmt.Println("Error", err)
	}

	workerInstance := *runResult.Instances[0].InstanceId

	err = ec2Svc.WaitUntilInstanceRunning(&ec2.DescribeInstancesInput{
		Filters: []*ec2.Filter{
			{
				Name: aws.String("instance-id"),
				Values: []*string{
					aws.String(workerInstance),
				},
			},
		},
	})
	if err != nil {
		fmt.Println("Error", err)
	}

	_, err = ec2Svc.AttachVolume(&ec2.AttachVolumeInput{
		Device:     aws.String("/dev/xvdz"),
		InstanceId: aws.String(workerInstance),
		VolumeId:   aws.String(volume),
	})
	if err != nil {
		fmt.Println("Error", err)
	}

	_, err = ec2Svc.TerminateInstances(&ec2.TerminateInstancesInput{
		InstanceIds: []*string{aws.String(workerInstance)}})
	if err != nil {
		fmt.Println("Error", err)
	}

	err = ec2Svc.WaitUntilInstanceTerminated(&ec2.DescribeInstancesInput{
		Filters: []*ec2.Filter{
			{
				Name: aws.String("instance-id"),
				Values: []*string{
					aws.String(workerInstance),
				},
			},
		},
	})

	_, err = ec2Svc.AttachVolume(&ec2.AttachVolumeInput{
		Device:     aws.String(rootDevName),
		InstanceId: aws.String(instanceId),
		VolumeId:   aws.String(volume),
	})
	if err != nil {
		fmt.Println("Error", err)
	}

	_, err = ec2Svc.StartInstances(&ec2.StartInstancesInput{
		InstanceIds: []*string{aws.String(instanceId)}})
	if err != nil {
		fmt.Println("Error", err)
	}

}

//func getWorkerInstance(zone, subnet) ec2 instance {
//}
