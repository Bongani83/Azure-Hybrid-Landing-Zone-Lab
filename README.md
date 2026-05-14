# Cost-Conscious Azure Hybrid Landing Zone - Terraform

This Terraform package recreates the cost-conscious Azure Hybrid Landing Zone lab.

## What this deploys

- Resource group
- Hub VNet: `10.20.0.0/16`
- Spoke VNet: `10.21.0.0/16`
- Simulated on-prem VNet: `192.168.50.0/24`
- Hub, spoke, and on-prem subnets
- NSGs and subnet associations
- VNet peerings:
  - Hub to Spoke
  - Hub to On-Prem
  - On-Prem to Spoke

## Cost-conscious design

This intentionally excludes higher-cost services:

- Azure VPN Gateway
- Azure Bastion
- Azure Firewall
- Sentinel
- Log Analytics ingestion
- Virtual machines

The ARM export included a VM, but the Terraform version excludes it to keep this safe for a free Azure subscription. You can add VMs later if needed.

## Why direct On-Prem to Spoke peering exists

Azure VNet peering is not transitive by default. For a low-cost lab, direct peering between the simulated on-prem VNet and the spoke VNet validates routing without deploying VPN Gateway or Azure Firewall.

## How to deploy

```bash
terraform init
terraform plan
terraform apply
```

## How to destroy

```bash
terraform destroy
```

## Portfolio note

This lab demonstrates:

- Azure landing zone thinking
- Hybrid network simulation
- Hub-and-spoke design
- NSG-based access control
- Cost-aware cloud architecture
- Infrastructure-as-Code using Terraform
