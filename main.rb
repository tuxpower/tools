require 'aws-sdk-ec2'

USAGE = <<DOC

Usage: main instance-id

Where:
  instance-id	(required) is the instance ID

DOC

def wait_for_instances(client, state, ids)
  begin
    client.wait_until(state, instance_ids: ids)
  rescue Aws::Waiters::Errors::WaiterFailed => error
    puts "Failed: #{error.message}"
  end
end

if ARGV.length > 0
  instance_id = ARGV[0]
else
  puts USAGE
  exit 1
end

# Get an Amazon EC2 resource
ec2 = Aws::EC2::Resource.new(region: 'eu-west-1')

# Get an Amazon EC2 client
client = Aws::EC2::Client.new

instance = ec2.instance(instance_id)

if instance.exists?
  puts "Root Device: #{instance.root_device_name}"
end

volumes = instance.volumes({
  filters: [
    {
      name: "attachment.device",
      values: [instance.root_device_name],
    },
  ],
})

volume = ""

volumes.each do |vol|
  puts "Volume ID: #{vol.volume_id}"
  volume = vol.volume_id
end

puts "Stopping instance ID #{instance_id}"
instance.stop

puts "Waiting for instance ID #{instance_id} to stop"
wait_for_instances(client, :instance_stopped, [instance_id])

puts "Detaching volume #{volume}"
instance.detach_volume({
  volume_id: volume,
})

puts "Launching worker instance..."
resp = client.run_instances({
  image_id: "ami-ca0135b3",
  instance_type: "t2.micro",
  key_name: "jgaspar",
  max_count: 1,
  min_count: 1,
  placement: {
    availability_zone: instance.placement.availability_zone,
  }, 
  subnet_id: instance.subnet_id,
})

worker_instance = ec2.instance(resp.instances[0].instance_id)
puts "Waiting for worker instance ID #{worker_instance.instance_id} to be running"
wait_for_instances(client, :instance_running, [worker_instance.instance_id])

puts "Attaching volume to worker instance"
worker_instance.attach_volume({
  device: "/dev/xvdz",
  volume_id: volume,
})

puts "Terminating worker instance"
worker_instance.terminate
puts "Waiting for worker instance ID #{worker_instance.instance_id} to be terminated"
wait_for_instances(client, :instance_terminated, [worker_instance.instance_id])

puts "Attaching volume back to original instance"
instance.attach_volume({
  device: instance.root_device_name,
  volume_id: volume,
})

puts "Starting original instance"
instance.start
puts "Waiting for original instance ID #{instance_id} to be running again"
wait_for_instances(client, :instance_running, [instance_id])
