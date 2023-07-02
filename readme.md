# Module tf-admin

Creates two roles:

* `-admin` role manages the AWS account
* `-github` role is assumed by a GitHub Actions worker. 
  Then this role assumes both the `-admin` and `-state-manager` roles.
