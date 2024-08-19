# lucidlink-client-packer-aws
Packer AMI builder for AWS EC2 instance with LucidLink client configured as systemd service

## Prerequisites

Dependencies for deployment:

1. AWS account with IAM credentials set as environmental variables on the system running the scripts.
2. Packer installed: [packer](https://developer.hashicorp.com/packer/install)
3. macOS or Linux system to download source files and run scripts and commands

<!-- OVERVIEW -->
### Overview
This template utilizes Packer to create a custom AMI with all software dependencies installed and a systemd service configured for the chosen LucidLink Filespace. After setting various input variables, Terraform is used to deploy the integrated services in an AWS VPC.

<!-- INSTALLATION -->
### Installation and execution steps

1. Clone the repo
   ```sh
   git clone https://github.com/dmcp718/lucidlink-client-packer-aws.git
   ```
2. The repo tree structure:
   ```sh
.
├── LICENSE
├── README.md
└── packer
    ├── images
    │   ├── ll-client.pkr.hcl
    │   └── variables.auto.pkrvars.hcl
    └── script
        ├── config_vars.txt
        └── ll-client_ami_build_args.sh
   ```
3. Edit the packer/script/config_vars.text file:
   ```
   FILESPACE1="filespace.domain"
   FSUSER1="username"
   LLPASSWD1="password"
   ROOTPOINT1="/"
   ```
4. Run the ll-client_ami_build_args.sh script:
   ```sh
   cd lucidlink-client-packer-aws/packer/script
   sudo chmod +x ll-client_ami_build_args.sh
   ./ll-client_ami_build_args.sh
   ```
5. Edit packer variables:
   ```sh
   cd ../images
   nano variables.auto.pkrvars.hcl
   ```
   ```sh
   region = "us-east-2"

   instance_type = "c6a.2xlarge"

   filespace = "filespace-name"
   ```
6. Run packer build:
   ```sh
   packer build ll-client.pkr.hcl
   ```