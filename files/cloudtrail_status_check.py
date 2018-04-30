import os
import boto3


def answer_no(x): return True if str(x).lower() in [
    '0', 'no', 'false'] else False


def answer_yes(x): return True if str(x).lower() in [
    '1', 'yes', 'true'] else False


def send_notifications(message):
    # TODO
    return True


def is_bucket_not_public(bucket_name):
    s3 = boto3.client('s3')
    bucket_acl = s3.get_bucket_acl(Bucket=bucket_name)

    # If there is a permission attached with any value for AllUsers,
    # it means the bucket is public
    # We don't need to check if the permission any of
    # READ|WRITE|READ_ACP|WRITE_ACP|FULL_CONTROL
    for grantee in bucket_acl['Grants']:
        if grantee['Grantee']['Type'] == 'Group' \
                and grantee['Grantee']['URI'] == 'http://acs.amazonaws.com/groups/global/AllUsers':
            return False
    return True


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

        if not is_bucket_not_public(trail['S3BucketName']):
            rc = 1
            notification = trail['Name'] + \
                "\'s bucket has public access."
            print notification
            message_body += notification + "\n"

    if rc == 1 and ('DRY_RUN' in os.environ and answer_no(os.environ['DRY_RUN'])):
        send_notifications(message_body)
        exit(rc)

# if __name__ == "__main__":
#    event = 1
#    context = 1
#    lambda_handler(event, context)
