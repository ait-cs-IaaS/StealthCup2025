#!/usr/bin/env python3

import boto3
import json
from datetime import datetime
from botocore.exceptions import ClientError
from collections import defaultdict
import shutil
import os
import sys
import re
import argparse
import subprocess

# Configuration
TEAM_TAG_KEY = "team"
TEAM_TAG_VALUE = -1
NAME = ""
TFVARS_DIR = "terragrunt"  # Directory where amis.auto.tfvars.json resides
TFVARS_FILENAME = "team_images.auto.tfvars.json"
AWS_REGION = "eu-central-1"  # Adjust to your desired region

TEAM_NAME_PATTERN = re.compile(r"^(team(?:[0-9]{,2}))_([a-zA-Z0-9_-].+)$")  # Matches team0_<name> to team20_<name>

waiterconfig = {
        'Delay': 15,
        'MaxAttempts': 999
    }

def get_instances(ec2_client):
    """
    Retrieve instances with a specific tag.
    """
    try:
        response = ec2_client.describe_instances(
            Filters=[
#                {
#                    'Name': f'tag:{TEAM_TAG_KEY}',
#                    'Values': [TEAM_TAG_VALUE]
#                },
                {
                    'Name': 'instance-state-name',
                    'Values': ['running']
                }
            ]
        )
    except ClientError as e:
        print(f"Error fetching instances: {e}")
        return []
    
    instances = []
    for reservation in response.get('Reservations', []):
        for instance in reservation.get('Instances', []):
            instance_id = instance.get('InstanceId')
            
            name = next((tag['Value'] for tag in instance.get('Tags', []) if tag['Key'] == 'Name'), instance.get('InstanceId'))

            if TEAM_NAME_PATTERN.match(name): # check if team in name exists
                team = re.match(TEAM_NAME_PATTERN, name).group(1) # get team
                instance_name = re.match(TEAM_NAME_PATTERN, name).group(2) # get team
                #print(team, instance_name)
            else: 
                print(f"skipping {name} as team regex does not match (no snapshot required)")
                continue

            if TEAM_TAG_VALUE >= 0:
                if team != f"team{TEAM_TAG_VALUE}":
                    print(f"skipping {name} since we only create AMIs for team{TEAM_TAG_VALUE}")
                    continue
            if NAME != None:
                if instance_name != NAME:
                    print(f"skipping {name} since we only create AMIs for hosts {NAME}")
                    continue

            instances.append((instance_id, team, instance_name))
    return instances

def confirm_action(msg):
    """Ask the user for confirmation before proceeding."""
    response = input(f"{msg} Type 'yes' to proceed: ").strip().lower()
    return response == "yes"

def main():
    """
    1. Load existing AMIs from amis.auto.tfvars.json.
    2. Describe instances with the specific tag.
    3. Create AMIs for each instance.
    4. Wait for each AMI to become available.
    5. Merge new AMIs with existing ones and write back to amis.auto.tfvars.json.
    """

    # Initialize Argument Parser
    parser = argparse.ArgumentParser(description="Process optional group ID and host name.")

    # Add optional arguments
    parser.add_argument("-g", "--group_id", type=int, help="Specify the group ID (integer).", default=0)
    parser.add_argument("-n", "--name", type=str, help="Specify the host name.", default=None)
    parser.add_argument("-f", "--full", action=argparse.BooleanOptionalAction, help="Taint all hosts of team.", default=False)
    parser.add_argument("-v", "--verbose", action=argparse.BooleanOptionalAction, help="Verbosity.", default=False)

    # Parse arguments
    args = parser.parse_args()

    # Store values
    global TEAM_TAG_VALUE
    global NAME
    TEAM_TAG_VALUE = args.group_id  # Will be None if not provided
    NAME = args.name  # Will be None if not provided
    machines_skipped = ['dmz_domain_controller', 'dmz_historian', 'dmz_jump', 'enterprise_client', 'enterprise_domain_controller', 'enterprise_file_server', 'monitoring_otids', 'supervision_engineer_workstation', 'supervision_scada']

    # Print for debugging
    if args.verbose:
        print(f"TEAM_TAG_VALUE: {TEAM_TAG_VALUE}")
        print(f"NAME: {NAME}")
    
    #json_file = sys.argv[1]
    
    # Initialize boto3 EC2 client
    ec2_client = boto3.client('ec2', region_name=AWS_REGION)
    
    # Step 2: Get instances with the specific tag
    instances = get_instances(ec2_client)
    if not instances:
        print(f"No running instances found with tag {TEAM_TAG_KEY}={TEAM_TAG_VALUE}.")
        sys.exit(0)
    
    print(f"Found {len(instances)} instance(s) with tag {TEAM_TAG_KEY}={TEAM_TAG_VALUE}:")
    commands = []

    for instance_id, team, name in instances:
        if not args.full:
            if name in machines_skipped:
                if args.verbose:
                    print(f'Skipping {name}')
                continue

        commands.append(f'terragrunt taint module.infrastructure[\\"{team}\\"].aws_instance.{name}')
    
    print('\n'.join(commands))
    if not confirm_action('Are you sure you want to taint these resources?'):
        print("Operation cancelled. No resources were tainted.")
        exit(1)
    

    subprocess.run(" && ".join(commands), shell=True, check=True)

    subprocess.run("terragrunt plan 2>&1 | egrep -i '(replaced|replacement|destroy)'", shell=True, check=True)

    if confirm_action("Do you want to apply?"):
        subprocess.run("terragrunt apply", shell=True, check=True)


if __name__ == "__main__":
    main()


