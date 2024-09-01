# Chapter 2 - Getting Started with Terraform

## Setting Up Your ~~AWS~~ OCI Account

[Oracle Cloud Infrastructure](https://www.oracle.com/cloud/) (OCI), similarly to Amazon Web Services
(AWS), has a way for you to try out its services. If you go to [https://www.oracle.com/cloud/free/](https://www.oracle.com/cloud/free/)
and follow the instructions you can sign up for an Oracle Cloud 
[Free Tier](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier.htm) account.

Signing up will create a Free Tier OCI tenancy and tenancy administrator account. The account comes
with an amount of time limited trial credits allowing you to try many OCI services. After the trial
period it then drops down to only allowing you access to "Always Free" resources.

For my examples I'm going to assume that you're using the tenancy administrator account for testing
and learning. For production use you will probably want to set up separate users with different 
roles and access rights for specific tasks. See 
[Account and Access Concepts](https://docs.oracle.com/en-us/iaas/Content/GSG/Concepts/concepts-account.htm)
to get started with this.

Once you've got your OCI tenancy setup, you'll also want to install the OCI [command line 
interface](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cliconcepts.htm) tool `oci`on
the machine that you'll be using for practice. See the 
[Quickstart install instructions](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm)
for the details of how to install and set that up for your particular machine.

In my case there was already a [package](https://src.fedoraproject.org/rpms/oci-cli) included with
Fedora 39, so I could install it just by running:

```shell
sudo dnf install oci-cli
```

Once you've installed the OCI CLI you can create a configuration file for it by running the command:

```shell
oci setup config
```

The command provides references for where to find the information you need to set it up and walks 
you step-by-step through the process. On a Linux system the default location for the OCI CLI 
configuration is `$HOME\.oci\config`. You should end up with something that looks like:

```ignorelang
[DEFAULT]
tenancy=<YOUR_TENANCY_OCID>
user=<YOUR_USER_OCID>
fingerprint=<YOUR_API_KEY_FINGERPRINT>
key_file=<THE_PATH_TO_YOUR_API_KEY_PRIVATE_KEY>
region=<YOUR_HOME_REGION_NAME>
```

or a bit more specifically:

```ignorelang
[DEFAULT]
tenancy=ocid1.tenancy.oc1.<rest_of_tenancy_ocid>
user=ocid1.user.oc1.<rest_of_user_ocid>
fingerprint=99:<rest_of_api_key_fingerprint>
key_file=~/.oci/<rest_of_api_key_path>
region=uk-london-1
```

To test that your `oci` CLI is setup and working with the DEFAULT profile you can try running:

```shell
oci iam region list
```

if you've got your DEFAULT profile properly setup with API key authentication it should return the 
list of available OCI regions e.g:

```ignorelang
$ oci iam region list
{
  "data": [
    {
      "key": "AMS",
      "name": "eu-amsterdam-1"
    },
    {
      "key": "ARN",
      "name": "eu-stockholm-1"
    },
.
.
.
    {
      "key": "YYZ",
      "name": "ca-toronto-1"
    },
    {
      "key": "ZRH",
      "name": "eu-zurich-1"
    }
  ]
}
$
```

### A Note on ~~Default Virtual Private Clouds~~ Virtual Cloud Networks

OCI, unlike AWS, does not have a Default VPC. Instead, we'll need to create a 
[Virtual Cloud Network](https://docs.oracle.com/en-us/iaas/Content/GSG/Concepts/concepts-core.htm#concepts-vcn)
(VCN) and specify the IP address space that we want to use. This will make the OCI examples 
slightly larger than the AWS ones.

VCNs are region specific resources, so you need to define at least one VCN for each region that you 
want to deploy infrastructure into. A VCN does however span all the availability domains in each 
region.

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
sudo dnf install -y tofu
```
(I substituted `dnf` for `yum` but using `yum` would probably works equally well. On contemporary 
Fedora derived Linuxes e.g. Red Hat Enterprise Linux, Oracle Linux, `yum` is now aliased to 
`dnf`.)

I found out later that there's a [package](https://src.fedoraproject.org/rpms/opentofu) available
for Fedora 39 as well, so I could've installed it just by running:

```shell
sudo dnf install opentofu
```

As with Terraform, you can test whether things are working by running the `tofu` command which 
should give the usage instructions:

```ignorelang
$ tofu
Usage: tofu [global options] <subcommand> [args]

The available commands for execution are listed below.
The primary workflow commands are given first, followed by
less common or more advanced commands.

Main commands:
  init          Prepare your working directory for other commands
  validate      Check whether the configuration is valid
.
.
.
  version       Show the current OpenTofu version
  workspace     Workspace management

Global options (use these before the subcommand, if any):
  -chdir=DIR    Switch to a different working directory before executing the
                given subcommand.
  -help         Show this help output, or the help for a specified subcommand.
  -version      An alias for the "version" subcommand.
$
```
