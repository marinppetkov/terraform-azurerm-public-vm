# Azure linux VM with Data Disks and NFS

## Purpose

This setup is intended for training in Azure, Terraform, and Linux.

## Details

The configuration deploys a Linux VM in Azure with a public connection, attached data disks, and a bash script to mount the external drives.</br>

This setup follows the steps below:
1. An Azure VNET and subnet is created.
2. A security group is configured to open the SSH port, allowing the file provisioner to upload the `mount.sh` script.
3. The VM is deployed, and the disks are attached.
4. The bash script is executed via [Virtual machine extensions](https://learn.microsoft.com/en-us/azure/virtual-machines/extensions/features-linux?tabs=azure-cli)
5. Storage account with files share and private endpoint is created 

![example](/diagram/visual.png)

## To do 
Update main.sh to add LUN targets dynamically.</br>

### Notes
An RSA key-pair is generated locally, so a new key pair must be created before using this code.
