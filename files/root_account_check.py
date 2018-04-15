import boto3


def send_notifications(message):
    # TODO
    return True


def lambda_handler(event, context):
    iam = boto3.client('iam')
    message_body = ""

    account_summary = iam.get_account_summary()

    if account_summary['SummaryMap']['AccountAccessKeysPresent'] != 0:
        notification = "Root account has an access key. It should be removed\n"
        print notification
        message_body += notification

    if account_summary['SummaryMap']['AccountMFAEnabled'] != 1:
        notification = "Root account does not have MFA set up\n"

    # TODO
    # There will be check if the root account's MFA device is a hardware oneself.
    # First, I need to have one that I can test while I develop

    if message_body:
        send_notifications(message_body)
    else:
        print 'Everything seems fine'

# if __name__ == "__main__":
#    event = 1
#    context = 1
#    lambda_handler(event, context)
