import subprocess
#subprocess.call(["ssh", "-i", "/home/jgaspar/.ssh/id_jgaspar", "-o", "ProxyCommand=''ssh -i /home/jgaspar/.ssh/id_ecdsa -W %h:%p joseg@46.51.200.4''", "ec2-user@172.18.14.237", "sudo", "mount", "/dev/xvdz1", "/mnt"])
subprocess.call(["scp", "-i", "/home/jgaspar/.ssh/id_jgaspar", "-o", "ProxyCommand=''ssh -i /home/jgaspar/.ssh/id_ecdsa -W %h:%p joseg@46.51.200.4''", "/home/jgaspar/.ssh/id_ecdsa.pub", "ec2-user@172.18.14.237:"])
