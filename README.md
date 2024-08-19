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
   ├── bootstrap.sh
   └── packer
      ├── images
      │   ├── ami_id.txt
      │   ├── custom-vars.pkrvars.hcl
      │   ├── ll-client.pkr.hcl
      │   └── manifest.json
      └── script
         ├── config_vars.txt
         └── ll-client_ami_build_args.sh
   ```
3. Edit the packer/script/config_vars.text file. The plain text password value is encoded to base64 for transfer to the EC2 instance during the build process, where it is encrypted using `systemd-creds`. The temp base64 password file is then shredded using `shred`:
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
5. To customize the AMI, update the variables in the custom-vars.pkrvars.hcl file:
   ```sh
   cd ../images
   nano custom-vars.pkrvars.hcl
   ```
   ```sh
   region = "us-east-2"

   instance_type = "c6a.2xlarge"

   filespace = "filespace-domain"
   ```
6. Run packer build specifying with the custom variables file:
   ```sh
   packer build -var-file="custom-vars.pkrvars.hcl" ll-client.pkr.hcl
   ```
7. After the AMI is created, use the AMI ID to deploy the instance in AWS. Attach the `bootstrap.sh` script to the instance as a user data script to format the `data` disk and start the LucidLink client service.
