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

instance = ec2.instance(instance_id)

if instance.exists?
  puts "Root Device: #{instance.root_device_name}"
end

puts "AZ: #{instance.placement.availability_zone}"
puts "Subnet: #{instance.subnet_id}"

volumes_result = instance.volumes({
  filters: [
    {
			name: "attachment.device",
			values: [instance.root_device_name], 
    },
  ],
})

vol = ""

volumes_result.each do |volume|
  puts "=" * 10
  puts "Volume ID: #{volume.volume_id}"
  vol = volume.volume_id
end

puts "Vol ID: #{vol}"

instance.stop

client = Aws::EC2::Client.new

begin
  client.wait_until(:instance_stopped, instance_ids:[instance_id])
  puts "instance stopped"
rescue Aws::Waiters::Errors::WaiterFailed => error
  puts "failed waiting for instance stopping: #{error_message}"
end

instance.detach_volume({
  volume_id: vol,
})

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
wait_for_instances(client, :instance_running, [worker_instance.instance_id])

puts "Worker ID: #{worker_instance.instance_id}"

worker_instance.attach_volume({
	device: "/dev/xvdz",
	volume_id: vol,
})

worker_instance.terminate
wait_for_instances(client, :instance_terminated, [worker_instance.instance_id])
