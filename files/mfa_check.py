import os
import boto3
import datetime


def answer_no(x): return True if str(x).lower() in [
    '0', 'no', 'false'] else False


def answer_yes(x): return True if str(x).lower() in [
    '1', 'yes', 'true'] else False


def mask_key(key):
    masked = ""
    if type(key) is str:
        masked = key[:5] + '*' * (len(key) - 9) + key[-4:]
    elif type(key) is list:
        for i in key:
            masked = masked + ',' + mask_key(i)
    return masked


def send_notifications(message):
    # TO DO
    return True


def disable_users(users):
    iam = boto3.client('iam')

    message_body = 'AGGRESSIVE is set to ' + os.environ['AGGRESSIVE'] \
        if ('AGGRESSIVE' in os.environ and answer_yes(os.environ['AGGRESSIVE'])) else ""
    print message_body

    for user in users:
        if 'DRY_RUN' not in os.environ or answer_no(os.environ['DRY_RUN']):
            if 'AGGRESSIVE' in os.environ and answer_yes(os.environ['AGGRESSIVE']):

                user_notification = 'Deleting ' + user + "'s login profile"
                print user_notification
                message_body = "\n" + user_notification

                try:
                    iam.delete_login_profile(UserName=user)
                except Exception, e:
                    print('Skipping User {} has no login profile'.format(user))

                try:
                    access_keys = iam.list_access_keys(UserName=user)
                except Exception, e:
                    print('Skipping. User {} has no access key'.format(user))

                if 'AccessKeyMetadata' in access_keys:
                    for key in access_keys['AccessKeyMetadata']:
                        key_notification = 'User ' + user + "'s key " + \
                            mask_key(key['AccessKeyId']) + ' will be deleted'
                        print key_notification
                        message_body = "\n" + key_notification
                        iam.delete_access_key(
                            UserName=key['UserName'], AccessKeyId=key['AccessKeyId'])
        else:
            no_action = "DRY_RUN has been set and the %s is not disabled" % user
            print no_action
            message_body = message_body + "\n" + no_action

    if len(users) > 0 and ('DRY_RUN' in os.environ and answer_no(os.environ['DRY_RUN'])):
        send_notifications(message_body)


def lambda_handler(event, context):
    iam = boto3.client('iam')
    users = iam.list_users()
    non_mfa_users = []
    prefix_list = os.environ['IGNORE_IAM_USER_PREFIX'].split(
        ',') if 'IGNORE_IAM_USER_PREFIX' in os.environ else []
    suffix_list = os.environ['IGNORE_IAM_USER_SUFFIX'].split(
        ',') if 'IGNORE_IAM_USER_SUFFIX' in os.environ else []

    for user in users['Users']:
        print('Processing ' + user['UserName'])
        mfa = iam.list_mfa_devices(UserName=user['UserName'])

        if not mfa['MFADevices']:
            non_mfa_users.append(user['UserName'])
            for ignore_prefix in prefix_list:
                if user['UserName'].startswith(ignore_prefix):
                    non_mfa_users.remove(user['UserName'])
            for ignore_suffix in suffix_list:
                if user['UserName'].endswith(ignore_suffix):
                    non_mfa_users.remove(user['UserName'])
    print "The following users do not have MFA set up, so should be removed."
    print non_mfa_users
    disable_users(non_mfa_users)

# if __name__ == "__main__":
#    event = 1
#    context = 1
#    lambda_handler(event, context)
