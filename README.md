# CORE: Kubernetes

This repository contains Terraform to add core services to an empty Kubernetes platform.

This includes:
- DNS Zones
- Ingress Controller ([AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller))
  - [`external-dns`](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.6/guide/integrations/external_dns/) to manage Route 53 DNS entries for Ingress
- `metrics-server`
- Storage Providers:
  - AWS EFS

## READ THIS FIRST

You need to have installed `aws-vault`, `aws-cli` and configured your access before you can run anything.

Read more here to understand how to do this.

The rest of this documentation assumes you have created an AWS Vault profile called `vendorcorp`.

## Technologies Used

- [Terraform](https://www.terraform.io/downloads.html) v1.4.5: What you'll find in this repository!
- AWS Vault: You need this to access Sonatype AWS Accounts

## Running Terraform

Use Terraform:
```
aws-vault exec vendorcorp -- terraform init
aws-vault exec vendorcorp -- terraform plan
aws-vault exec vendorcorp -- terraform apply
```

# The Fine Print

At the time of writing I work for Sonatype, and it is worth nothing that this is **NOT SUPPORTED** bu Sonatype - it is purely a contribution to the open source community (read: you!).

Remember:
- Use this contribution at the risk tolerance that you have
- Do NOT file Sonatype support tickets related to cheque support in regard to this project
- DO file issues here on GitHub, so that the community can pitch in