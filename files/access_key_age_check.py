import os
import boto3
import datetime

iam = boto3.client('iam')


def answer_no(x): return True if str(x).lower() in [
    '0', 'no', 'false'] else False


def answer_yes(x): return True if str(x).lower() in [
    '1', 'yes', 'true'] else False


def mask_key(key):
    masked = ""
    if type(key) is str:
        masked = key[:5] + '*' * (len(key) - 10) + key[-5:]
    elif type(key) is list:
        for i in key:
            masked = masked + mask_key(i)
    return masked


def send_notifications(message):
    # TODO
    return True


def process_expring_keys(users):
    message_body = 'AGGRESSIVE is set to ' + os.environ['AGGRESSIVE'] \
        if ('AGGRESSIVE' in os.environ and answer_yes(os.environ['AGGRESSIVE'])) \
        else "AGGRESSIVE mode is not active"
    print message_body

    key_age_max = int(
        os.environ['KEY_AGE_MAX']) if 'KEY_AGE_MAX' in os.environ else 90
    key_age_notify = int(
        os.environ['KEY_AGE_NOTIFY']) if 'KEY_AGE_NOTIFY' in os.environ else 7

    notification = 'Notify: ' + \
        str(key_age_notify) + ', Expire: ' + str(key_age_max)
    print notification
    message_body += "\n" + notification

    for user, access_key in users.iteritems():
        for key_id, expirity in access_key.iteritems():
            if expirity >= key_age_max:
                if 'AGGRESSIVE' in os.environ and answer_yes(os.environ['AGGRESSIVE']):
                    notification = 'Deleting ' + user + "'s key " + \
                        mask_key(key_id) + ' due to expiration'
                    print notification
                    message_body += "\n" + notification
                    iam.delete_access_key(UserName=user, AccessKeyId=key_id)
                else:
                    notification = user + "'s key " + \
                        mask_key(key_id) + ' ' + str(expirity) + \
                        ' old, so should be deleted'
                    print notification
                    message_body += "\n" + notification
            elif expirity < key_age_max and expirity >= key_age_max - key_age_notify:
                notification = user + "'s key " + mask_key(key_id) \
                    + ' will be expiring in ' + str(expirity) + ' days.' \
                    + 'It should be rotated soon'
                print notification
                message_body += "\n" + notification

    if len(users) > 0 and ('DRY_RUN' in os.environ and answer_no(os.environ['DRY_RUN'])):
        send_notifications(message_body)
    else:
        print "Nothing to do. Either there is no user to process or DRY_RUN is active"


def lambda_handler(event, context):
    users = iam.list_users()

    prefix_list = os.environ['IGNORE_IAM_USER_PREFIX'].split(
        ',') if 'IGNORE_IAM_USER_PREFIX' in os.environ else []
    suffix_list = os.environ['IGNORE_IAM_USER_SUFFIX'].split(
        ',') if 'IGNORE_IAM_USER_SUFFIX' in os.environ else []

    def is_user_ignored(prefix_list, suffix_list, name):
        for prefix in prefix_list:
            if name.startswith(prefix):
                return True
        for prefix in suffix_list:
            if name.endswith(prefix):
                return True
        return False

    keys_to_process = {}

    for user in users['Users']:
        if not is_user_ignored(prefix_list, suffix_list, user['UserName']):
            print 'Processing ' + user['UserName']
            access_keys = iam.list_access_keys(UserName=user['UserName'])

            for key in access_keys['AccessKeyMetadata']:
                today = datetime.datetime.utcnow().replace(
                    tzinfo=key['CreateDate'].tzinfo)
                delta = today - key['CreateDate']
                if key['UserName'] not in keys_to_process:
                    keys_to_process[key['UserName']] = {}
                keys_to_process[key['UserName']].setdefault(
                    key['AccessKeyId'], delta.days)

    process_expring_keys(keys_to_process)

# if __name__ == "__main__":
#    event = 1
#    context = 1
#    lambda_handler(event, context)
