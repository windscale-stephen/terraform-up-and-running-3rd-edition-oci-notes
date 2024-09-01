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

One thing you'll come across repeatedly when dealing with OCI are
[OCIDs](https://docs.oracle.com/en-us/iaas/Content/GSG/Concepts/concepts-account.htm). An OCID is 
the unique identifier that OCI assigns to many of the resources you can create in OCI. Different types of 
OCID have 
[different formats](https://docs.oracle.com/en-us/iaas/Content/General/Concepts/identifiers.htm).

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
configuration is `$HOME/.oci/config`. You should end up with something that looks like:

```ignorelang
[DEFAULT]
tenancy=<YOUR_TENANCY_OCID>
user=<YOUR_USER_OCID>
fingerprint=<YOUR_API_KEY_FINGERPRINT>
key_file=<THE_PATH_TO_YOUR_API_KEY_PRIVATE_KEY>
region=<YOUR_HOME_REGION_NAME>
```

or a bit more specifically, if your home region is "uk-london-1":

```ignorelang
[DEFAULT]
tenancy=ocid1.tenancy.oc1.<rest_of_tenancy_ocid>
user=ocid1.user.oc1.<rest_of_user_ocid>
fingerprint=FF:<rest_of_api_key_fingerprint>
key_file=~/.oci/<rest_of_api_key_path>
region=uk-london-1
```

To test that your `oci` CLI is setup and working with the DEFAULT profile and API key
authentication you can try running:

```shell
oci iam region list
```

If everything works that should return the list of available OCI regions e.g:

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

## Deploying a Single Server

To setup the OCI provider to use API key authentication and to get the other configuration it 
needs from the DEFAULT profile in your OCL CLI config add the following to `main.tf`:

```hcl
provider "oci" {
  auth = "APIKey"
  config_file_profile = "DEFAULT"
}
```

We've specified the region to deploy to in our DEFAULT profile, so we don't need to configure it 
here.

The first resource we need is to configure is a VCN:

```hcl
resource "oci_core_vcn" "example_vcn" {
  compartment_id = "<tenancy_ocid>"
  cidr_blocks = ["10.0.0.0/16"]
}
```

Replace `<tenancy_ocid>` with the OCID of your tenancy. You need to do this for the other 
resources below as well.

This creates the VCN in the root
[compartment](https://docs.oracle.com/en-us/iaas/Content/GSG/Concepts/concepts-account.htm#concepts-access)
of our tenancy, gives it the name `example_vcn` so we can refer to it in the rest of code, and
tells OCI that we're planning to use IP addresses from the 10.0.0.0/16 
[CIDR block](https://erikberg.com/notes/networks.html).

Next we'll create a subnet resource called `example_subnet`:

```hcl
resource "oci_core_subnet" "example_subnet" {
  cidr_block = "10.0.1.0/24"
  compartment_id = "<tenancy_ocid>"
  vcn_id = oci_core_vcn.example_vcn.id
  prohibit_public_ip_on_vnic = true # Make this a private subnet
}
```

This subnet is allocated the block of addresses 10.0.1.0/24 which is a valid subnet of 10.0.0.0/16.
We're also creating this subnet in the root compartment of the tenancy. For safety, we're making 
this subnet a private subnet by specifying `prohibit_public_ip_on_vnic = true`. This means resources 
created in this subnet won't be accessible from The Internet.

In order to create the subnet we have to provide the OCID of the VCN we want to subnet to be a 
part of. To do that we're using an _attribute reference_ to get the `id` attribute of the
`oci_core_vcn` resource called `example_vcn` which we're going to create. The `id` attribute
contains the OCID of the created VCN. The book doesn't cover attribute references until the section
"Deploying a Cluster of Web Servers" later in Chapter 2.

Now we can finally get to creating the compute instance resource that we need to deploy the server:

```hcl
resource "oci_core_instance" "example_instance" {
  availability_domain = "Lguh:UK-LONDON-1-AD-3"
  compartment_id = "<tenancy_ocid>"
  shape = "VM.Standard.E2.1.Micro"
  source_details {
    source_type = "image"
    # Oracle-Linux-8.10-2024.07.31-0 in uk-london-1
    source_id = "ocid1.image.oc1.uk-london-1.aaaaaaaay6agryw3wg52ruxw56zns3azgwgki3ireaugsuhmfvfnjplxsrfa"
  }
  create_vnic_details {
    subnet_id = oci_core_subnet.example_subnet.id
    assign_public_ip = false # Shouldn't need this because prohibit_public_ip_on_vnic = true in
                             # subnet
  }
  preserve_boot_volume = false
}
```

We have to tell OCI which availability domain we want to deploy the image in. I logged onto the 
OCI console and selected "Compute / Instances" from the hamburger menu and then clicked the 
"Create instance" button to see which availability domain was _Always Free-eligible_. In my case 
that was "Lguh:UK-LONDON-1-AD-3" in my home region of "uk-london-1". We then tell OCI to create the 
instance in the root compartment of the tenancy as we've done for the VCN and subnet.

We then have to tell OCI which type of instance to create. Here I've specified a VM of _shape_ 
"VM.Standard.E2.1.Micro" which is an x86_64 architecture VM with an AMD processor and 1 GiB of 
memory. This instance shape is eligible for the OCI Free Tier so we won't be charged for it if 
we remain within the Free Tier limits for that shape.

In the `source_details` section, we're telling OCI which operating system we want the instance 
to run. Setting `source_type = "image"` specifies that we're going to provide the OCID of the 
image that we want to use to provision this VM. In my case I'm providing the OCID of the Oracle 
Linux 8 image "Oracle-Linux-8.10-2024.07.31-0" in my home region of "uk-london-1".

In the `create_vnic_details` section, we're telling OCI which subnet we want the primary VNIC of 
the host to be in. Again, we're using an attribute reference to get the `id` attribute of the
`oci_core_subnet` resource called `example_subnet`. This attribute contains the OCID of the 
subnet we're going to create. Currently I've also specified `assign_public_ip = false` because 
of an oddity I discovered. The documentation for `oci_core_instance` says that this should 
default to false if the subnet is a private subnet (`prohibit_public_ip_on_vnic = true`) but I 
found I couldn't create the instance unless I specified `assign_public_ip = false`.

Finally, I'm also specifying `preserve_boot_volume = false` so when we destroy this instance it 
will also terminate the boot volume associated with it.

For convenience, the complete configuration is in [main.tf](01-deploying-single-server/main.tf).
