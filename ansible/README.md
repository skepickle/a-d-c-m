# Nimbus Development Environment Ansible

This repository contains [Ansible](https://www.ansible.com/) roles and playbooks to install, upgrade and manage the cloud environments used to develop Nimbus.

## Setup

1. Install base dependencies:

    ***

    Requirements:
    - Ansible >= 2.2.0

    ***

    RedHat Enterprise Linux 6.x:
    ```
    wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
    sudo yum install ./epel-release-latest-6.noarch.rpm
    sudo yum install ansible
    ```

2. Setup for a specific cloud:

    - [AWS](README_AWS.md)

3. Running the playbook:

    - AWS:
        ```
        ansible-playbook -i aws site.yml
        ```
