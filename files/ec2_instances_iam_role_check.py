import os
import boto3


def answer_no(x): return True if str(x).lower() in [
    '0', 'no', 'false'] else False


def answer_yes(x): return True if str(x).lower() in [
    '1', 'yes', 'true'] else False


def send_notifications(message):
    # TODO
    return True


def process_regions(regions):
    message_body = ''

    for region, instances in regions.iteritems():
        message_body = 'Region ' + region + \
            " has following instances without an IAM Instance Profile\n"
        message_body += "\n".join(instances)

    print message_body

    if len(regions) > 0 and ('DRY_RUN' in os.environ and answer_no(os.environ['DRY_RUN'])):
        send_notifications(message_body)
    else:
        print "Nothing to do. Either everything is fine or DRY_RUN is active"


def lambda_handler(event, context):
    regions_to_process = {}

    ec2 = boto3.client('ec2')

    regions = ec2.describe_regions()

    for region in regions['Regions']:

        print 'Processing region ' + region['RegionName']

        # Create a new client for the region
        ec2_region = boto3.client('ec2', region_name=region['RegionName'])
        # Create a paginator to filter
        paginator = ec2_region.get_paginator('describe_instances')
        page_iterator = paginator.paginate()
        # Filter with JMESPath and find out instances without an IAM Instance profile
        filtered_iterator = page_iterator.search(
            'Reservations[].Instances[].{InstanceId: InstanceId, InstanceProfileArn: IamInstanceProfile.Arn} | [?@.InstanceProfileArn == null].InstanceId')

        for instance in filtered_iterator:
            if region['RegionName'] not in regions_to_process:
                regions_to_process.setdefault(region['RegionName'], [])
            regions_to_process[region['RegionName']].append(instance)

    process_regions(regions_to_process)


# if __name__ == "__main__":
#    event = 1
#    context = 1
#    lambda_handler(event, context)
