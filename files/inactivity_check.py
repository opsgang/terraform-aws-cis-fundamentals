import os
import boto3
import datetime

iam = boto3.client('iam')
inactivity_limit = int(
    os.environ['INACTIVITY_LIMIT']) if 'INACTIVITY_LIMIT' in os.environ else 90


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
    # TODO
    return True


def is_user_logged_in(user_name):
    user_details = iam.get_user(UserName=user_name)

    if 'PasswordLastUsed' in user_details['User']:
        last_login = user_details['User']['PasswordLastUsed']
    else:
        last_login = user_details['User']['CreateDate']

    today = datetime.datetime.utcnow().replace(tzinfo=last_login.tzinfo)
    last_login_delta = today - last_login

    if last_login_delta.days > inactivity_limit:
        return False

    return True


def is_access_key_used(access_key_id):
    access_key_last_used = iam.get_access_key_last_used(
        AccessKeyId=access_key_id)
    # if the key is never used, there is no LastUsedDate item
    if 'LastUsedDate' in access_key_last_used['AccessKeyLastUsed']:
        last_used = access_key_last_used['AccessKeyLastUsed']['LastUsedDate']
        today = datetime.datetime.utcnow().replace(tzinfo=last_used.tzinfo)
        access_key_last_used_delta = today - last_used
        if access_key_last_used_delta.days > inactivity_limit:
            return False
    return True


def delete_credentials(users):
    message_body = 'AGGRESSIVE is set to ' + os.environ['AGGRESSIVE'] \
        if ('AGGRESSIVE' in os.environ and answer_yes(os.environ['AGGRESSIVE'])) \
        else "AGGRESSIVE mode is not active"
    print message_body

    for user in users:
        if 'DRY_RUN' not in os.environ or answer_no(os.environ['DRY_RUN']):
            if 'AGGRESSIVE' in os.environ and answer_yes(os.environ['AGGRESSIVE']):
                user_notification = 'Deleting ' + user + "'s login profile"
                print user_notification
                message_body += "\n" + user_notification

                try:
                    iam.delete_login_profile(UserName=user)
                except Exception, e:
                    print 'Skipping User ' + user + ' has no login profile'

                try:
                    access_keys = iam.list_access_keys(UserName=user)
                except Exception, e:
                    print 'Skipping. User ' + user + ' has no access key'

                if 'AccessKeyMetadata' in access_keys:
                    for key in access_keys['AccessKeyMetadata']:
                        key_notification = 'User ' + user + "'s key " + \
                            mask_key(key['AccessKeyId']) + ' will be deleted'
                        print key_notification
                        message_body = "\n" + key_notification
                        iam.delete_access_key(
                            UserName=key['UserName'], AccessKeyId=key['AccessKeyId'])
            else:
                user_notification = user + ' is not an active user, so should be disabled'
                print user_notification
                message_body += "\n" + user_notification
        else:
            no_action = "DRY_RUN has been set and the %s is not disabled" % user
            print no_action
            message_body += "\n" + no_action

    if len(users) > 0 and ('DRY_RUN' in os.environ and answer_no(os.environ['DRY_RUN'])):
        send_notifications(message_body)
    else:
        print "Nothing to do"


def lambda_handler(event, context):
    print 'Inactivity Limit ' + str(inactivity_limit)
    inactive_users = []

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

    users = iam.list_users()

    for user in users['Users']:
        if not is_user_ignored(prefix_list, suffix_list, user['UserName']):
            any_key_used = False

            logged_in = is_user_logged_in(user['UserName'])

            access_keys = iam.list_access_keys(UserName=user['UserName'])
            for key in access_keys['AccessKeyMetadata']:
                if is_access_key_used(key['AccessKeyId']):
                    any_key_used = True

            if not logged_in and not any_key_used:
                inactive_users.append(user['UserName'])
    delete_credentials(inactive_users)

# if __name__ == "__main__":
#    event = 1
#    context = 1
#    lambda_handler(event, context)
