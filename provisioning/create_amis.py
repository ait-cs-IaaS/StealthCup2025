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

# Configuration
TEAM_TAG_KEY = "team"
TEAM_TAG_VALUE = 0
NAME = ""
TFVARS_DIR = "terragrunt"  # Directory where amis.auto.tfvars.json resides
TFVARS_FILENAME = "team_images.auto.tfvars"
AWS_REGION = "eu-central-1"  # Adjust to your desired region

TEAM_NAME_PATTERN = re.compile(r"^(team(?:[0-9]{,2}))_([a-zA-Z0-9_-].+)$")  # Matches team0_<name> to team20_<name>

waiterconfig = {
        'Delay': 15,
        'MaxAttempts': 999
    }

def load_existing_amis():
    """
    Load existing AMI mappings from amis.auto.tfvars.json if it exists.
    """
    tfvars_path = os.path.join(TFVARS_DIR, TFVARS_FILENAME)
    if not os.path.isfile(tfvars_path):
        print(f"No existing {TFVARS_FILENAME} found. Starting fresh.")
        return {}
    
    try:
        with open(tfvars_path, 'r') as f:
            data = json.load(f)
            return data.get("team_images", {})
    except json.JSONDecodeError as e:
        print(f"Error: Failed to parse {TFVARS_FILENAME}: {e}. Starting fresh.")
        return {}

def save_amis(amis, timestamp_str):
    """
    Write the AMI mappings to a timestamped JSON file and replace the main amis.auto.tfvars.json.
    """
    # Create a timestamped filename
    timestamped_filename = f"{TFVARS_FILENAME}_{timestamp_str}"
    timestamped_path = os.path.join(TFVARS_DIR, timestamped_filename)
    
    tfvars_data = {"team_images": amis}
    
    # Write the timestamped file
    try:
        with open(timestamped_path, "w") as f:
            json.dump(tfvars_data, f, indent=2)
        print(f"Written AMI mappings to {timestamped_filename}:")
        print(json.dumps(tfvars_data, indent=2))
    except IOError as e:
        print(f"Error writing to {timestamped_filename}: {e}")
        return
    
    # Path to the main tfvars file
    main_tfvars_path = os.path.join(TFVARS_DIR, TFVARS_FILENAME)
    
    # Replace the main tfvars file with the new one
    try:
        shutil.copyfile(timestamped_path, main_tfvars_path)
        print(f"Replaced {TFVARS_FILENAME} with {timestamped_filename}")
    except IOError as e:
        print(f"Error replacing {TFVARS_FILENAME} with {timestamped_filename}: {e}")

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
                    'Values': ['stopped']
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

            if TEAM_TAG_VALUE > 0:
                if team != f"team{TEAM_TAG_VALUE}":
                    print(f"skipping {name} since we only create AMIs for team{TEAM_TAG_VALUE}")
                    continue
            if NAME != None:
                if instance_name != NAME:
                    print(f"skipping {name} since we only create AMIs for hosts {NAME}")
                    continue

            instances.append((instance_id, team, instance_name))
    return instances

def create_ami(ec2_client, instance_id, team, name):
    """
    Create an AMI from the given instance.
    """
    timestamp = datetime.now().strftime("%Y%m%d-%H%M")
    ami_name = f"{team}_{name}-{timestamp}-{instance_id}"
    try:
        response = ec2_client.create_image(
            InstanceId=instance_id,
            Name=ami_name,
            Description=f"AMI from instance {instance_id} ({team}_{name})",
            NoReboot=False  # Optional: set to False if you prefer a reboot during AMI creation
        )
        ami_id = response['ImageId']
        print(f"Initiated creation of AMI {ami_id} for instance {instance_id} ({team}_{name})")
        return ami_id
    except ClientError as e:
        print(f"Error creating AMI for instance {instance_id} ({team}_{name}): {e}")
        return None

def wait_for_ami(ec2_client, ami_id):
    """
    Wait until the AMI is available.
    """
    print(f"Waiting for AMI {ami_id} to become available...")
    try:
        waiter = ec2_client.get_waiter('image_available')
        waiter.wait(ImageIds=[ami_id], WaiterConfig=waiterconfig)
        print(f"AMI {ami_id} is now available.")
        return True
    except ClientError as e:
        print(f"Error waiting for AMI {ami_id}: {e}")
        return False
    
def wait_for_amis(ec2_client, ami_ids):
    print(f"Waiting for {len(ami_ids)} AMIs to become available...")
    try:
        waiter = ec2_client.get_waiter('image_available')
        waiter.wait(ImageIds=ami_ids, WaiterConfig=waiterconfig)
        print("All AMIs are now available.")
        return True
    except ClientError as e:
        print(f"Error waiting for AMIs: {e}")
        return False

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
    parser.add_argument("-t", "--test", action=argparse.BooleanOptionalAction, help="Test only, do not run.", default=False)

    # Parse arguments
    args = parser.parse_args()

    # Store values
    global TEAM_TAG_VALUE
    global NAME
    TEAM_TAG_VALUE = args.group_id  # Will be None if not provided
    NAME = args.name  # Will be None if not provided

    # Print for debugging
    print(f"TEAM_TAG_VALUE: {TEAM_TAG_VALUE}")
    print(f"NAME: {NAME}")
    
    #json_file = sys.argv[1]
    
    # Initialize boto3 EC2 client
    ec2_client = boto3.client('ec2', region_name=AWS_REGION)
    
    # Step 1: Load existing AMIs
    existing_amis = load_existing_amis()
    
    # Step 2: Get instances with the specific tag
    instances = get_instances(ec2_client)
    if not instances:
        print(f"No running instances found with tag {TEAM_TAG_KEY}={TEAM_TAG_VALUE}.")
        sys.exit(0)
    
    print(f"Found {len(instances)} instance(s) with tag {TEAM_TAG_KEY}={TEAM_TAG_VALUE}:")
    for instance_id, team, name in instances:
        print(f"  - {instance_id} ({team}_{name})")
    
    # Step 3: Create AMIs for each instance
    new_amis = defaultdict(dict)
    ami_ids = []
    for instance_id, team, name in instances:
        ami_id = "ami-00000000000000"
        if not args.test:
            ami_id = create_ami(ec2_client, instance_id, team, name)
        if ami_id:
            #success = wait_for_ami(ec2_client, ami_id)
            #success = True
            #if success:
            new_amis[team][name] = ami_id
            ami_ids.append(ami_id)
    
    # Step 4: Merge new AMIs with existing AMIs but only update changed values
    if new_amis:
        updated_amis = existing_amis.copy()  # Copy to preserve existing data

        for team, instances in new_amis.items():
            if team not in updated_amis:
                updated_amis[team] = {}  # Ensure the team key exists

            for name, ami_id in instances.items():
                if updated_amis[team].get(name) != ami_id:  # Only update if different
                    updated_amis[team][name] = ami_id

        # Get current timestamp
        timestamp_str = datetime.now().strftime("%Y%m%d_%H%M")

        # Step 5: Write only modified AMIs back to amis.auto.tfvars.json
        save_amis(updated_amis, timestamp_str)
    else:
        print("No new AMIs were successfully created.")

    if ami_ids and not args.test:
        wait_for_amis(ec2_client, ami_ids)

if __name__ == "__main__":
    main()