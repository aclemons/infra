# Role Name

Configures certbot on Slackware Linux.

## Requirements

slackroll

## Role Variables

    certbot_email: ''

Set the email for cerbot.

    certbot_domains:

The domains to register certificates for.

## Dependencies

None

## Example Playbook

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    - hosts: all
      roles:
         - { role: certbot }

## License

BSD

## Author Information
