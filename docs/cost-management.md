# Cost-management checklist

Before creating any resource:
- [ ] Verify the AWS account, active CLI profile, and region.
- [ ] Review billing dashboard and existing budgets/alerts.
- [ ] Check current pricing for the chosen region (`ap-south-1` is the initial preferred region, not yet confirmed for this project).
- [ ] Identify resources that accrue hourly charges or data-transfer charges.
- [ ] Prefer local tests, synthetic data, and short-lived experiments first.
- [ ] Do not create NAT Gateways, RDS/Aurora instances, ElastiCache, Redshift, or always-on streaming without an explicit cost review.
- [ ] Set deletion/cleanup steps before deployment.
- [ ] Verify cleanup and check the billing dashboard after testing.

A budget or alert is not a hard spending cap. AWS usage can incur charges before an alert is delivered.
