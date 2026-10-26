# Compute hosts and Redshift regional adjustment

## EC2 host layer

The architecture requires an administration bastion and private application EC2 host; the private analytics worker is also available as an opt-in resource. The host layer is disabled by default. Enabling it requires a public SSH key and a narrow trusted `admin_cidr`. The local demo page binds only to loopback and is intended for review through an SSH tunnel, not a public website.

## Redshift for Mumbai

AWS documents `rg.large` single-node support in Mumbai on the current P204-or-later track. The configuration therefore defaults to `rg.large` and explicitly selects the current maintenance track. Redshift still incurs a material hourly charge; check current `ap-south-1` pricing and confirm the account's quota/track before deployment.

## Safety

No AWS resources are created by the installer. Host and worker flags remain `false` until the owner reviews the cost estimate and approves deployment. The planned 10-day reviewer environment must be destroyed and audited after the review period.
