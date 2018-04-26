import os
import boto3


def answer_no(x): return True if str(x).lower() in [
    '0', 'no', 'false'] else False


def answer_yes(x): return True if str(x).lower() in [
    '1', 'yes', 'true'] else False


def lambda_handler(event, context):
    rc = 1
    message_body = 'Chekcing trails'
    print message_body

    cloudtrail = boto3.client('cloudtrail')
    trails = cloudtrail.describe_trails()

    for trail in trails['trailList']:
        notification = 'Checking ' + trail['Name']
        print notification
        message_body += notification + "\n"

        if trail['IsMultiRegionTrail'] \
                and ('KmsKeyId' in trail and trail['KmsKeyId'] != '') \
                and trail['IncludeGlobalServiceEvents'] \
                and trail['LogFileValidationEnabled']:

            notification = trail['Name'] + ' is OK'
            print notification
            message_body += notification + "\n"
            rc = 0
        else:
            notification = trail['Name'] + \
                ' does not match with the requirements'
            print notification
            message_body += notification + "\n"

    if rc == 1 and ('DRY_RUN' in os.environ and answer_no(os.environ['DRY_RUN'])):
        send_notifications(message_body)
        exit(rc)

# if __name__ == "__main__":
#    event = 1
#    context = 1
#    lambda_handler(event, context)
