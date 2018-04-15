import os
import boto3

iam = boto3.client('iam')


def answer_no(x): return True if str(x).lower() in [
    '0', 'no', 'false'] else False


def answer_yes(x): return True if str(x).lower() in [
    '1', 'yes', 'true'] else False


def send_notifications(message):
    # TO DO
    return True


def detach_policies(users):
    message_body = 'AGGRESSIVE is set to ' + os.environ['AGGRESSIVE'] \
        if ('AGGRESSIVE' in os.environ and answer_yes(os.environ['AGGRESSIVE'])) \
        else 'AGGRESSIVE mode is not active'
    print message_body

    for user, policies in users.iteritems():
        notification = 'Processing ' + user
        print notification
        message_body += notification + "\n"
        for policy in policies:
            notification = policy['PolicyName'] + \
                ' will be detached from the user'
            print notification
            message_body += notification + "\n"
            if ('DRY_RUN' not in os.environ or answer_no(os.environ['DRY_RUN'])) \
                    and ('AGGRESSIVE' in os.environ and answer_yes(os.environ['AGGRESSIVE'])):
                iam.detach_user_policy(
                    UserName=user, PolicyArn=policy['PolicyArn'])
            else:
                notification = 'AGREESIVE is not active or DRY_RUN is enabled, so the policy is not removed'
                print notification
                message_body += notification + "\n"

    if len(users) > 0 and ('DRY_RUN' not in os.environ or answer_no(os.environ['DRY_RUN'])):
        send_notifications(message_body)
    else:
        print 'DRY_RUN is active and/or nothing to do'


def lambda_handler(event, context):
    users = iam.list_users()
    user_policies = {}

    for user in users['Users']:
        attached_policy_list = iam.list_attached_user_policies(
            UserName=user['UserName'])
        user_policy_list = iam.list_user_policies(UserName=user['UserName'])

        if len(attached_policy_list['AttachedPolicies']) > 0 \
                or len(user_policy_list['PolicyNames']) > 0:

            user_policies[user['UserName']] = attached_policy_list['AttachedPolicies'] + \
                user_policy_list['PolicyNames']
    detach_policies(user_policies)


# if __name__ == "__main__":
#    event = 1
#    context = 1
#    lambda_handler(event, context)
