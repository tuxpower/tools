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
