<?php
require 'vendor/autoload.php';

use Aws\Ec2\Ec2Client;

$ec2Client = new Ec2Client([
    'region' => 'eu-west-1',
    'version' => '2016-11-15',
    'profile' => 'default'
]);

$instance = $argv[1];

$result = $ec2Client->describeInstances();

// var_dump($result['Reservations'][0]['Instances'][0]['BlockDeviceMappings'][0]['DeviceName']);
// print($result->get('RootDeviceName')['Value'] . "\n");	// using the get() method of the php model
// print($result['RootDeviceName']['Value'] . "\n");		// accessing the result like an associative array
// print($result->search('RootDeviceName.Valiue') . "\n");	// executing JMESPath expression on the result data using the search() method

// https://aws.amazon.com/blogs/developer/provision-an-amazon-ec2-instance-with-php/
// From the result, we must get the ID of the instance. We do this using the getPath method available on the result object. This allows us to pull data out of the result that is deep within the result’s structure. The following line of code retrieves an array of instance IDs from the result. In this case, where we have launched only a single instance, the array contains only one value.
// 
// $instanceIds = $result->getPath('Instances/*/InstanceId');
// echo current($result->getPath('Reservations/*/Instances/*/PublicDnsName'))

$result = $ec2Client->describeInstanceAttribute([
    'Attribute' => 'rootDeviceName',
    'InstanceId' => $instance,
]);

$devname = $result->get('RootDeviceName')['Value'];

$result = $ec2Client->describeInstanceAttribute([
    'Attribute' => 'blockDeviceMapping',
    'InstanceId' => $instance,
]);

foreach ($result['BlockDeviceMappings'] as $block) {
    if ($block['DeviceName'] == $devname ) {
        $volume = $block['Ebs']['VolumeId'] . "\n";
    }
}

$ec2Client->stopInstances(array(
    'InstanceIds' => array($instance)
));

// Wait until the instance is stopped
$ec2Client->waitUntil('InstanceStopped', (array(
    'InstanceIds' => array($instance)
)));
?>
