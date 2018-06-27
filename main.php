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

var_dump($result['Reservations'][0]['Instances'][0]['BlockDeviceMappings'][0]['DeviceName']);

$result = $ec2Client->describeInstanceAttribute([
    'Attribute' => 'rootDeviceName',
    'InstanceId' => $instance,
]);

//var_dump($result);
print($result->get('RootDeviceName')['Value']."\n");	// using the get() method of the php model
print($result['RootDeviceName']['Value']."\n");		// accessing the result like an associative array
print($result->search('RootDeviceName.Value')."\n");	// executing JMESPath expression on the result data using the search() method
?>
