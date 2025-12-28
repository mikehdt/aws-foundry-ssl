# Changelog

### TODO

- Custom VPC support with fallback to default VPC

### v3.0.0-alpha - Security and logging improvements

- (breaking) Uplift: Updated Foundry service paths for V13+ zip structure (no longer uses `resources/app/` subdirectory)
- (breaking) Removed: IAM Admin User is no longer created; It was unrelated to Foundry's operation and a security concern
- New: Setup log (`/tmp/foundry-setup.log`) now streams to CloudWatch for real-time deployment monitoring
- New: Nginx error log now streams to CloudWatch
- New: Timestamped logging in setup scripts for better debugging
- New: CloudFormation Outputs section with Foundry URL, instance IP, and S3 bucket name
- New: Added `AllowedPattern` validation for SSH IPv4/IPv6 CIDR inputs
- New: Foundry health check service that auto-restarts Foundry if unresponsive (fixes V11+ 502 errors after in-place updates)
- New: Cost management tags (`Application`, `StackName`) on all AWS resources for billing visibility
- Security: Secrets (AWS access keys) are no longer leaked in setup logs
- Fix: Proper DLM (Data Lifecycle Manager) role for EBS snapshots; Previously used the EC2 instance role incorrectly
- Fix: S3 bucket name regex pattern now correctly validates (removed errant pipe characters)
- Fix: Security group resource names now match their actual purpose (HTTP, HTTPS, TURN, Voice)
- Fix: Removed unnecessary `sudo` calls throughout scripts (already running as root)
- Fix: Uninitialised `edit_retry` variable in foundry.sh
- Fix: Double `echo` typo in foundry.sh
- Fix: Incorrect script name references in utility scripts
- Uplift: Renamed CloudWatch log groups for consistency (`foundry-*` prefix)
- Uplift: Node.js 24 LTS
- Uplift: Amazon Linux 2023 kernel 6.12
- Docs: Fixed typos and removed outdated IAM Admin User references

### v2.1.0 - Upgrade compatibility

- Changed the security group to be based on the stack name
- Changed the server name to be based on the stack name
- Less restrictive IAM Admin Username

### v2.0.0 - Rework config

- (breaking) New: Config to enable mainline nginx 1.25 to make the `http2` option a little more sane
- (breaking) Uplift: CloudFormation config is now YAML; Some of the script stuff is much tidier
- Uplift: Less `sudo` everywhere where it's not needed
- Uplift: R53 recordset updates now happen synchronously as well so that Certbot can start a little faster
- Fix: Node install and lint errors - thanks @samdammers!
- Fix: Google Drive downloads
- Fix: nginx version upgrade priority for mainline
- Removed non-Graviton instance types

### v1.2.0 - Experimental IPv6

- New: **Experimental** IPv6 support (as long as your subnet is configured)
- Fix: Some systemd timer configurations
- Fix: Minor script tweaks to make it a little more resilient

### v1.1.0 - Autopatching

https://github.com/mikehdt/aws-foundry-ssl/releases/tag/v1.1.0

- New: Amazon Linux 2023 kernel auto-updating
- Various tweaks and minor style fixes

### v1.0.0 - Initial Rework

https://github.com/mikehdt/aws-foundry-ssl/releases/tag/v1.0.0

- New: Send certbot's update logs to CloudWatch
- New: Can choose to _not_ request LetsEncrypt TLS if you're trying to get it to deploy and you don't want to run into the certificate issuance limit. See https://letsencrypt.org/docs/duplicate-certificate-limit/
- Fix: S3 bucket ACL permissions were updated for the stricter [default policy](https://aws.amazon.com/about-aws/whats-new/2022/12/amazon-s3-automatically-enable-block-public-access-disable-access-control-lists-buckets-april-2023/) as of circa April 2023
- Fix: S3 permissions and configuration was changed in Foundry 11
- Fix: New default AMI security seems to necessitate `sudo` in the install script
- Fix: LetsEncrypt TLS certbot didn't work on initial startup
- Fix: Seemed to be a conflict between running the install scripts on the EC2 and CloudFormation setting up the DNS
- Fix: Fixed legacy option warning in `certbot`'s CLI call
- Fix: Some AWS Route53 issues where a `.` needed to be on the end of the domain
- Uplift: `yum` calls were changed use `dnf`. `yum` itself [is deprecated](https://github.com/rpm-software-management/yum) in favour of `dnf`.
- Uplift: All legacy `crontab` timers have been migrated to [`systemd` timers](https://wiki.archlinux.org/title/Systemd/Timers)
- Uplift: Node install script [was deprecated](https://github.com/nodesource/distributions); Instead it installs with `dnf`
- Uplift: `amazon-linux-extras` [no longer exists](https://aws.amazon.com/linux/amazon-linux-2023/faqs/); Instead it installs `nginx` with `dnf`
- Uplift: Tidied up some other bits and pieces, added a few extra echoes to help diagnose logging
- Uplift: `t4g` instances are cheaper for very similar workloads so they're now the default, `t3a` instances are still available
  - Foundry would _just_ run on a `.micro` instance, but it'd also run out of memory and cause the EC2 to freak out. This resulted in CPU usage (and hosting costs) to spiral out of control, so that size has been removed
  - `m6`-class instances added for people who are made of moneybags, replacing the older `m4` instances

### Removed Features

- Removed code for dealing with non-AWS registrars, as I don't have the means or time to support them
  - If you use a non-AWS registrar, you probably know what you're doing and can re-implement or configure it
