import os
import boto3

iam = boto3.client('iam')


def answer_no(x): return True if str(x).lower() in [
    '0', 'no', 'false'] else False


def answer_yes(x): return True if str(x).lower() in [
    '1', 'yes', 'true'] else False


def send_notifications(message):
    # TODO:
    return True


def if_policy_attached_to_any_group(arn):
    entities = iam.list_entities_for_policy(
        PolicyArn=arn,
        EntityFilter='Group',
    )
    return entities['PolicyGroups']


def if_any_group_has_users(groups):
    for group in groups:
        group_detail = iam.get_group(
            GroupName=group['GroupName'],
            MaxItems=1,
        )
        if len(group_detail['Users']) > 0:
            return True
    return False


def lambda_handler(event, context):
    rc = 1
    message = "Checking if the AWSSupportAccess policy attached to any group"
    print message

    paginator = iam.get_paginator('list_policies')
    page_iterator = paginator.paginate()
    # Filter with JMESPath and find out instances without an IAM Instance profile
    filtered_iterator = page_iterator.search(
        'Policies[?PolicyName == `AWSSupportAccess`].Arn')

    for arn in filtered_iterator:
        groups = if_policy_attached_to_any_group(arn)

        if len(groups) > 0:
            groups_has_user = if_any_group_has_users(groups)
            if groups_has_user:
                notification = 'Everthing is fine.'
                print notification
                message += notification
                rc = 0
            else:
                notification = 'None of the groups have user attached'
                print notification
                message += notification
        else:
            notification = 'AWSSupportAccess is not attached to any group'
            print notification
            message += notification + "\n"
    send_notifications(message)
    exit(rc)


# if __name__ == "__main__":
#    event = 1
#    context = 1
#    lambda_handler(event, context)
