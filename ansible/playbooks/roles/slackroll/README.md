# Role Name

Configures slackroll on Slackware Linux. This will install slackroll if needed.

## Requirements

None

## Role Variables

    slackroll_mirror: 'http://slackware.osuosl.org/slackware64-15.0/'

Set the primary mirror to use with slackroll. It will default to OSUOSL's mirror for the host's slackware version.

    slackroll_caffe_pkg_repo_base: <encrypted>

Set the base for the caffe repository.

    slackroll_caffe_pkg_repo: {{ slackroll_caffe_pkg_repo_base }}/<slackware-version>/<slackware-arch>/

Set the repo for the caffe repository.

    slackroll_alien_multilib_enabled: false

Whether to configure AlienBOB's multilib as a repo.

    slackroll_alien_sbrepo_enabled: false

Whether to configure AlienBOB's sbrepo as a repo.

    slackroll_alien_restricted_sbrepo_enabled: false

Whether to configure AlienBOB's restricted sbrepo as a repo.

## Dependencies

None

## Example Playbook

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    - hosts: servers
      roles:
         - { role: slackroll }

## License

BSD

## Author Information
