import os
import boto3


def send_notifications(message):
    # TODO
    return True


def lambda_handler(event, context):
    iam = boto3.client('iam')
    message_body = ""

    try:
        policy = iam.get_account_password_policy()
    except:
        message_body = 'Account has no password policy'
        print message_body

    require_uppercase_characters = bool(
        os.environ['REQUIRE_UPPERCASE_CHARACTERS']) if 'REQUIRE_UPPERCASE_CHARACTERS' in os.environ else True
    require_lowercase_characters = bool(
        os.environ['REQUIRE_LOWERCASE_CHARACTERS']) if 'REQUIRE_LOWERCASE_CHARACTERS' in os.environ else True
    require_symbols = bool(
        os.environ['REQUIRE_SYMBOLS']) if 'REQUIRE_SYMBOLS' in os.environ else True
    require_numbers = bool(
        os.environ['REQUIRE_NUMBERS']) if 'REQUIRE_NUMBERS' in os.environ else True
    minimum_password_length = int(
        os.environ['MINIMUM_PASSWORD_LENGTH']) if 'MINIMUM_PASSWORD_LENGTH' in os.environ else 14
    password_reuse_prevention = int(
        os.environ['PASSWORD_REUSE_PREVENTION']) if 'PASSWORD_REUSE_PREVENTION' in os.environ else 24
    max_password_age = int(
        os.environ['MAX_PASSWORD_AGE']) if 'MAX_PASSWORD_AGE' in os.environ else 90
    allow_users_to_change_password = bool(
        os.environ['ALLOW_USERS_TO_CHANGE_PASSWORD']) if 'ALLOW_USERS_TO_CHANGE_PASSWORD' in os.environ else True
    hard_expiry = bool(os.environ['HARD_EXPIRY']
                       ) if 'HARD_EXPIRY' in os.environ else True

    if not message_body:
        if policy['PasswordPolicy']['RequireUppercaseCharacters'] != require_uppercase_characters:
            message_body += "Require an uppercase letter has been set incorrectly\n"

        if policy['PasswordPolicy']['RequireLowercaseCharacters'] != require_lowercase_characters:
            message_body += "Require an lowercase letter has been set incorrectly\n"

        if policy['PasswordPolicy']['RequireSymbols'] != require_symbols:
            message_body += "Require a symbol has been set incorrectly\n"

        if policy['PasswordPolicy']['RequireNumbers'] != require_numbers:
            message_body += "Require a number has been set incorrectly\n"

        if policy['PasswordPolicy']['MinimumPasswordLength'] != minimum_password_length:
            message_body += "Minimum password length has been set incorrectly\n"

        if policy['PasswordPolicy']['MaxPasswordAge'] != max_password_age:
            message_body += "Maximum password age has been set incorrectly\n"

        if policy['PasswordPolicy']['AllowUsersToChangePassword'] != allow_users_to_change_password:
            message_body += "Allow users to change password has been set incorrectly\n"

        if policy['PasswordPolicy']['HardExpiry'] != hard_expiry:
            message_body += "Hard password expiry has been set incorrectly\n"

    if message_body:
        send_notifications(message_body)
    else:
        print 'Everything seems fine'
