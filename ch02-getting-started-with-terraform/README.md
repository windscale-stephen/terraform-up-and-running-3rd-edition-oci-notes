# Chapter 2 - Getting Started with Terraform

## Setting Up Your OCI Account

[Oracle Cloud Infrastructure](https://www.oracle.com/cloud/) (OCI), similarly to Amazon Web Services
(AWS), has a way for you to try out its services. If you go to [https://www.oracle.com/cloud/free/](https://www.oracle.com/cloud/free/)
and follow the instructions you can sign up for an Oracle Cloud 
[Free Tier](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier.htm)  account.

Signing up will create a Free Tier OCI tenancy and tenancy administrator account. The account comes
with an amount of time limited trial credits allowing you to try many OCI services. After the trial
period it then drops down to only allowing you access to "Always Free" resources.

For my examples I'm going to assume that you're using the tenancy administrator account for testing
and learning. For production use you will probably want to setup separate users with different 
roles and access rights for specific tasks. See 
[Account and Access Concepts](https://docs.oracle.com/en-us/iaas/Content/GSG/Concepts/concepts-account.htm)
to get started with this.

Once you've got your OCI tenancy setup, you'll also want to install the OCI [command line 
interface](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cliconcepts.htm) tool `oci`on
the machine that you'll be using for practice. You can find the Quickstart install instructions for 
the OCI CLI at
[https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm)
in my case there was already a [package](https://src.fedoraproject.org/rpms/oci-cli) included with
Fedora 39, so I could install it just by running:

```shell
sudo dnf install oci-cli
```

Once you've installed the OCI CLI you can create a configuration file for it by running the command:

```shell
oci setup config
```

The command provides references for where to find the information you need to set up the OCI CLI 
and walks you step-by-step through the process. On a Linux system the default location for the 
OCI CLI configuration is `$HOME\.oci\config`.

## Installing OpenTofu

The instructions for installing OpenTofu can be found at
[https://opentofu.org/docs/intro/install/](https://opentofu.org/docs/intro/install/). On my 
Fedora 39 laptop I followed the instructions for 
[RHEL and derivatives (.rpm)](https://opentofu.org/docs/intro/install/rpm/), specifically the 
Step by Step instructions for Yum (RHEL/AlmaLinux/etc.):

* Add the OpenTofu repos by creating the required file in /etc/yum.repos.d:

```shell
cat >/etc/yum.repos.d/opentofu.repo <<EOF
[opentofu]
name=opentofu
baseurl=https://packages.opentofu.org/opentofu/tofu/rpm_any/rpm_any/\$basearch
repo_gpgcheck=0
gpgcheck=1
enabled=1
gpgkey=https://get.opentofu.org/opentofu.gpg
       https://packages.opentofu.org/opentofu/tofu/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300

[opentofu-source]
name=opentofu-source
baseurl=https://packages.opentofu.org/opentofu/tofu/rpm_any/rpm_any/SRPMS
repo_gpgcheck=0
gpgcheck=1
enabled=1
gpgkey=https://get.opentofu.org/opentofu.gpg
       https://packages.opentofu.org/opentofu/tofu/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300
EOF
```

* Install the OpenTofu RPMs:

```shell
sudo yum install -y tofu
```

I found out later that there's a [package](https://src.fedoraproject.org/rpms/opentofu) available
for Fedora 39 as well, so I could've installed it just by running:

```shell
sudo dnf install opentofu
```

