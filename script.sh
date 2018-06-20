#!/usr/bin/env bash

set -eux

function usage_message() {
  echo "Usage: script -k bastion_key> -i <bastion_ip> -u <bastion_user> -K <ec2_key> -I <ec2_ip> -U <ec2_user>" 1>&2
}

if [ $# -eq 0 ]; then
  usage_message
  exit 1
fi

while getopts ":k:i:u:K:I:U:" opt; do
  case ${opt} in
    k)
      BASTION_KEY=${OPTARG}
    ;;
    i)
      BASTION_IP=${OPTARG}
    ;;
    u)
      BASTION_USER=${OPTARG}
    ;;
    K)
      EC2_KEY=${OPTARG}
    ;;
    I)
      EC2_INSTANCE=${OPTARG}
    ;;
    U)
      EC2_USER=${OPTARG}
    ;;
    :)
      echo "Invalid option: -${OPTARG} requires an argument" 1>&2
      usage_message
      exit 1
    ;;
   \?)
      echo "Unimplemented option: -${OPTARG}" 1>&2
      usage_message
      exit 1
    ;;
  esac
 done
shift $((OPTIND -1))

#BASTION_KEY=$1
#BASTION_IP=$2
#BASTION_USER=$3
#EC2_KEY=$4
#EC2_INSTANCE=$5
#EC2_USER=$6

ssh -t -i ${EC2_KEY} -o ProxyCommand="ssh -i ${BASTION_KEY} -W %h:%p ${BASTION_USER}@${BASTION_IP}" ${EC2_USER}@${EC2_INSTANCE} \
	"sudo mount /dev/xvdz1 /mnt;" \
	"sudo cat id_ecdsa.pub > /mnt/home/${EC2_USER}/.ssh/authorized_keys;" \
	"sudo umount /mnt"

echo "Finished running script" 1>&2
exit 0
