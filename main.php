<?php
require 'vendor/autoload.php';

use Aws\Ec2\Ec2Client;

$ec2Client = new Ec2Client([
    'region' => 'eu-west-1',
    'version' => '2016-11-15',
    'profile' => 'default'
]);

$result = $ec2Client->describeInstances();

var_dump($result);
?>
