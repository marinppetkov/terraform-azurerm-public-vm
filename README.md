# Azure linux VM with Data Disks and LB

## Purpose

This setup is intended for training in Azure, Terraform, and Linux.

## Details

The configuration deploys a Linux VM in Azure with a public connection, attached data disks, and a bash script to mount the external drives.</br>

This setup follows the steps below:
1. An Azure VNET and subnet is created.
2. A security group is configured to open the SSH port, allowing the file provisioner to upload the `mount.sh` script.
3. The VM is deployed, and the disks are attached.
4. The bash script is executed via [Virtual machine extensions](https://learn.microsoft.com/en-us/azure/virtual-machines/extensions/features-linux?tabs=azure-cli)

## To do 
Update main.sh to add LUN targets dynamically.</br>
Install Nginx server and test LB</br>
