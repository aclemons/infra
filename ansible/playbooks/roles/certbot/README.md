# Role Name

Configures certbot on Slackware Linux.

## Requirements

slackroll

## Role Variables

    ntp_area: ''

Set the ntp pool area. It is empty by default and will thus use the Slackware default configuration.

    ntp_servers:
      - "0{{ '.' + ntp_area if ntp_area else '' }}.pool.ntp.org iburst"
      - "1{{ '.' + ntp_area if ntp_area else '' }}.pool.ntp.org iburst"
      - "2{{ '.' + ntp_area if ntp_area else '' }}.pool.ntp.org iburst"
      - "3{{ '.' + ntp_area if ntp_area else '' }}.pool.ntp.org iburst"

The ntp servers you'd like to use. Defaults to the Slackware defaults (if they were uncommented).

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
