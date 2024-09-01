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

Once you have your `main.tf` file setup, go to the directory where you created it in a terminal
and run the `tofu init` command. You should see output similar to the following:

```ignorelang
$ tofu init

Initializing the backend...

Initializing provider plugins...
- Finding latest version of hashicorp/oci...
- Installing hashicorp/oci v5.36.0...
- Installed hashicorp/oci v5.36.0 (signed, key ID 1533A49284137CEB)

Providers are signed by their developers.
If you'd like to know more about provider signing, you can read about it here:
https://opentofu.org/docs/cli/plugins/signing/

OpenTofu has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that OpenTofu can guarantee to make the same selections by default when
you run "tofu init" in the future.

OpenTofu has been successfully initialized!

You may now begin working with OpenTofu. Try running "tofu plan" to see
any changes that are required for your infrastructure. All OpenTofu commands
should now work.

If you ever set or change modules or backend configuration for OpenTofu,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
$ 
```
You can then run `tofu plan` to see what OpenTofu will do if you apply this configuration. Again
you should see something like:

```ignorelang
$ tofu plan

OpenTofu used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

OpenTofu will perform the following actions:

  # oci_core_instance.example_instance will be created
  + resource "oci_core_instance" "example_instance" {
      + availability_domain                 = "Lguh:UK-LONDON-1-AD-3"
      + boot_volume_id                      = (known after apply)
      + capacity_reservation_id             = (known after apply)
      + compartment_id                      = "ocid1.tenancy.oc1.<rest_of_tenancy_ocid>"
      + compute_cluster_id                  = (known after apply)
      + dedicated_vm_host_id                = (known after apply)
      + defined_tags                        = (known after apply)
      + display_name                        = (known after apply)
      + extended_metadata                   = (known after apply)
      + fault_domain                        = (known after apply)
      + freeform_tags                       = (known after apply)
      + hostname_label                      = (known after apply)
      + id                                  = (known after apply)
      + image                               = (known after apply)
      + instance_configuration_id           = (known after apply)
      + ipxe_script                         = (known after apply)
      + is_cross_numa_node                  = (known after apply)
      + is_pv_encryption_in_transit_enabled = (known after apply)
      + launch_mode                         = (known after apply)
      + metadata                            = (known after apply)
      + preserve_boot_volume                = false
      + private_ip                          = (known after apply)
      + public_ip                           = (known after apply)
      + region                              = (known after apply)
      + shape                               = "VM.Standard.E2.1.Micro"
      + state                               = (known after apply)
      + subnet_id                           = (known after apply)
      + system_tags                         = (known after apply)
      + time_created                        = (known after apply)
      + time_maintenance_reboot_due         = (known after apply)

      + create_vnic_details {
          + assign_ipv6ip          = (known after apply)
          + assign_public_ip       = "false"
          + defined_tags           = (known after apply)
          + display_name           = (known after apply)
          + freeform_tags          = (known after apply)
          + hostname_label         = (known after apply)
          + nsg_ids                = (known after apply)
          + private_ip             = (known after apply)
          + skip_source_dest_check = (known after apply)
          + subnet_id              = (known after apply)
          + vlan_id                = (known after apply)
        }

      + source_details {
          + boot_volume_size_in_gbs = (known after apply)
          + boot_volume_vpus_per_gb = (known after apply)
          + source_id               = "ocid1.image.oc1.uk-london-1.aaaaaaaay6agryw3wg52ruxw56zns3azgwgki3ireaugsuhmfvfnjplxsrfa"
          + source_type             = "image"
        }
    }

  # oci_core_subnet.example_subnet will be created
  + resource "oci_core_subnet" "example_subnet" {
      + availability_domain        = (known after apply)
      + cidr_block                 = "10.0.1.0/24"
      + compartment_id             = "ocid1.tenancy.oc1.<rest_of_tenancy_ocid>"
      + defined_tags               = (known after apply)
      + dhcp_options_id            = (known after apply)
      + display_name               = (known after apply)
      + dns_label                  = (known after apply)
      + freeform_tags              = (known after apply)
      + id                         = (known after apply)
      + ipv6cidr_block             = (known after apply)
      + ipv6cidr_blocks            = (known after apply)
      + ipv6virtual_router_ip      = (known after apply)
      + prohibit_internet_ingress  = (known after apply)
      + prohibit_public_ip_on_vnic = true
      + route_table_id             = (known after apply)
      + security_list_ids          = (known after apply)
      + state                      = (known after apply)
      + subnet_domain_name         = (known after apply)
      + time_created               = (known after apply)
      + vcn_id                     = (known after apply)
      + virtual_router_ip          = (known after apply)
      + virtual_router_mac         = (known after apply)
    }

  # oci_core_vcn.example_vcn will be created
  + resource "oci_core_vcn" "example_vcn" {
      + byoipv6cidr_blocks               = (known after apply)
      + cidr_block                       = (known after apply)
      + cidr_blocks                      = [
          + "10.0.0.0/16",
        ]
      + compartment_id                   = "ocid1.tenancy.oc1.<rest_of_tenancy_ocid>"
      + default_dhcp_options_id          = (known after apply)
      + default_route_table_id           = (known after apply)
      + default_security_list_id         = (known after apply)
      + defined_tags                     = (known after apply)
      + display_name                     = (known after apply)
      + dns_label                        = (known after apply)
      + freeform_tags                    = (known after apply)
      + id                               = (known after apply)
      + ipv6cidr_blocks                  = (known after apply)
      + ipv6private_cidr_blocks          = (known after apply)
      + is_ipv6enabled                   = (known after apply)
      + is_oracle_gua_allocation_enabled = (known after apply)
      + state                            = (known after apply)
      + time_created                     = (known after apply)
      + vcn_domain_name                  = (known after apply)
    }

Plan: 3 to add, 0 to change, 0 to destroy.

───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so OpenTofu can't guarantee to take exactly these actions if you run "tofu apply" now.
$ 
```

(For safety, I've edited out the details of my tenancy OCID.)

To actually deploy the infrastructure you run `tofu apply`:

```ignorelang
$ tofu apply

OpenTofu used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

OpenTofu will perform the following actions:

  # oci_core_instance.example_instance will be created
  + resource "oci_core_instance" "example_instance" {
      + availability_domain                 = "Lguh:UK-LONDON-1-AD-3"
      + boot_volume_id                      = (known after apply)
      + capacity_reservation_id             = (known after apply)
      + compartment_id                      = "ocid1.tenancy.oc1.<rest_of_tenancy_ocid>"
      + compute_cluster_id                  = (known after apply)
      + dedicated_vm_host_id                = (known after apply)
      + defined_tags                        = (known after apply)
      + display_name                        = (known after apply)
      + extended_metadata                   = (known after apply)
      + fault_domain                        = (known after apply)
      + freeform_tags                       = (known after apply)
      + hostname_label                      = (known after apply)
      + id                                  = (known after apply)
      + image                               = (known after apply)
      + instance_configuration_id           = (known after apply)
      + ipxe_script                         = (known after apply)
      + is_cross_numa_node                  = (known after apply)
      + is_pv_encryption_in_transit_enabled = (known after apply)
      + launch_mode                         = (known after apply)
      + metadata                            = (known after apply)
      + preserve_boot_volume                = false
      + private_ip                          = (known after apply)
      + public_ip                           = (known after apply)
      + region                              = (known after apply)
      + shape                               = "VM.Standard.E2.1.Micro"
      + state                               = (known after apply)
      + subnet_id                           = (known after apply)
      + system_tags                         = (known after apply)
      + time_created                        = (known after apply)
      + time_maintenance_reboot_due         = (known after apply)

      + create_vnic_details {
          + assign_ipv6ip          = (known after apply)
          + assign_public_ip       = "false"
          + defined_tags           = (known after apply)
          + display_name           = (known after apply)
          + freeform_tags          = (known after apply)
          + hostname_label         = (known after apply)
          + nsg_ids                = (known after apply)
          + private_ip             = (known after apply)
          + skip_source_dest_check = (known after apply)
          + subnet_id              = (known after apply)
          + vlan_id                = (known after apply)
        }

      + source_details {
          + boot_volume_size_in_gbs = (known after apply)
          + boot_volume_vpus_per_gb = (known after apply)
          + source_id               = "ocid1.image.oc1.uk-london-1.aaaaaaaay6agryw3wg52ruxw56zns3azgwgki3ireaugsuhmfvfnjplxsrfa"
          + source_type             = "image"
        }
    }

  # oci_core_subnet.example_subnet will be created
  + resource "oci_core_subnet" "example_subnet" {
      + availability_domain        = (known after apply)
      + cidr_block                 = "10.0.1.0/24"
      + compartment_id             = "ocid1.tenancy.oc1.<rest_of_tenancy_ocid>"
      + defined_tags               = (known after apply)
      + dhcp_options_id            = (known after apply)
      + display_name               = (known after apply)
      + dns_label                  = (known after apply)
      + freeform_tags              = (known after apply)
      + id                         = (known after apply)
      + ipv6cidr_block             = (known after apply)
      + ipv6cidr_blocks            = (known after apply)
      + ipv6virtual_router_ip      = (known after apply)
      + prohibit_internet_ingress  = (known after apply)
      + prohibit_public_ip_on_vnic = true
      + route_table_id             = (known after apply)
      + security_list_ids          = (known after apply)
      + state                      = (known after apply)
      + subnet_domain_name         = (known after apply)
      + time_created               = (known after apply)
      + vcn_id                     = (known after apply)
      + virtual_router_ip          = (known after apply)
      + virtual_router_mac         = (known after apply)
    }

  # oci_core_vcn.example_vcn will be created
  + resource "oci_core_vcn" "example_vcn" {
      + byoipv6cidr_blocks               = (known after apply)
      + cidr_block                       = (known after apply)
      + cidr_blocks                      = [
          + "10.0.0.0/16",
        ]
      + compartment_id                   = "ocid1.tenancy.oc1.<rest_of_tenancy_ocid>"
      + default_dhcp_options_id          = (known after apply)
      + default_route_table_id           = (known after apply)
      + default_security_list_id         = (known after apply)
      + defined_tags                     = (known after apply)
      + display_name                     = (known after apply)
      + dns_label                        = (known after apply)
      + freeform_tags                    = (known after apply)
      + id                               = (known after apply)
      + ipv6cidr_blocks                  = (known after apply)
      + ipv6private_cidr_blocks          = (known after apply)
      + is_ipv6enabled                   = (known after apply)
      + is_oracle_gua_allocation_enabled = (known after apply)
      + state                            = (known after apply)
      + time_created                     = (known after apply)
      + vcn_domain_name                  = (known after apply)
    }

Plan: 3 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  OpenTofu will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

oci_core_vcn.example_vcn: Creating...
oci_core_vcn.example_vcn: Creation complete after 1s [id=ocid1.vcn.oc1.uk-london-1.<rest_of_vcn_ocid>]
oci_core_subnet.example_subnet: Creating...
oci_core_subnet.example_subnet: Creation complete after 1s [id=ocid1.subnet.oc1.uk-london-1.<rest_of_subnet_ocid>]
oci_core_instance.example_instance: Creating...
oci_core_instance.example_instance: Still creating... [10s elapsed]
oci_core_instance.example_instance: Still creating... [20s elapsed]
oci_core_instance.example_instance: Still creating... [30s elapsed]
oci_core_instance.example_instance: Creation complete after 36s [id=ocid1.instance.oc1.uk-london-1.<rest_of_instance_ocid>]

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
$ 
```

If you now go to the OCI console and look in:

* "Networking / Virtual Cloud Networks",
* "Compute / Instances",

you should be able to see the VCN and instance that was created. If you click on the VCN you
should be able to see the subnet as well.

One difference between AWS and OCI is that instead of having empty names, the resources that
were created were given random names like:

* vcn20240901085500,
* subnet20240901085501,
* instance20240901085503.

Those names are not particularly descriptive in terms of telling us what those resources refer
to! In this instance we'd probably prefer if they were called "example_vcn", "example_subnet",
"example_instance" to match what we've called the resources in our `main.tf`. To do that we need
to add one of:

* `display_name = "example_vcn`
* `display_name = "example_subnet`
* `display_name = "example_instance`

to the relevant resource configuration. For example:

```hcl
resource "oci_core_instance" "example_instance" {
  display_name = "example_instance"
  availability_domain = "Lguh:UK-LONDON-1-AD-3"
  compartment_id = "<tenancy_ocid>"
  shape = "VM.Standard.E2.1.Micro"
  source_details {
    source_id = "ocid1.image.oc1.uk-london-1.aaaaaaaay6agryw3wg52ruxw56zns3azgwgki3ireaugsuhmfvfnjplxsrfa"
    # Oracle-Linux-8.10-2024.07.31-0 in uk-london-1
    source_type = "image"
  }
  create_vnic_details {
    subnet_id = oci_core_subnet.example_subnet.id
    assign_public_ip = false # Shouldn't need this because prohibit_public_ip_on_vnic = true in
                             # subnet
  }
  preserve_boot_volume = false
}
```
Since the display_name argument for those three resources is updatable, if you make those
changes and then run `tofu plan` you should see something like:

```ignorelang
$ tofu plan
oci_core_vcn.example_vcn: Refreshing state... [id=ocid1.vcn.oc1.uk-london-1.<rest_of_vcn_ocid>]
oci_core_subnet.example_subnet: Refreshing state... [id=ocid1.subnet.oc1.uk-london-1.<rest_of_subnet_ocid>]
oci_core_instance.example_instance: Refreshing state... [id=ocid1.instance.oc1.uk-london-1.<rest_of_instance_ocid>]

OpenTofu used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  ~ update in-place

OpenTofu will perform the following actions:

  # oci_core_instance.example_instance will be updated in-place
  ~ resource "oci_core_instance" "example_instance" {
      ~ display_name         = "instance20240901085503" -> "example_instance"
        id                   = "ocid1.instance.oc1.uk-london-1.<rest_of_instance_ocid>"
        # (19 unchanged attributes hidden)

        # (7 unchanged blocks hidden)
    }

  # oci_core_subnet.example_subnet will be updated in-place
  ~ resource "oci_core_subnet" "example_subnet" {
      ~ display_name               = "subnet20240901085501" -> "example_subnet"
        id                         = "ocid1.subnet.oc1.uk-london-1.<rest_of_subnet_ocid>"
        # (15 unchanged attributes hidden)
    }

  # oci_core_vcn.example_vcn will be updated in-place
  ~ resource "oci_core_vcn" "example_vcn" {
      ~ display_name             = "vcn20240901085500" -> "example_vcn"
        id                       = "ocid1.vcn.oc1.uk-london-1.<rest_of_vcn_ocid>"
        # (14 unchanged attributes hidden)
    }

Plan: 0 to add, 3 to change, 0 to destroy.

───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so OpenTofu can't guarantee to take exactly these actions if you run "tofu apply" now.
$ 
```

If you then run `tofu apply`, wait for it to complete, and then check the OCI console, you
should see that Names have updated to the ones we specified.

Finally, we can clean up all of these resources by simply running `tofu destroy`:

```ignorelang
$ tofu destroy
oci_core_vcn.example_vcn: Refreshing state... [id=ocid1.vcn.oc1.uk-london-1.<rest_of_vcn_ocid>]
oci_core_subnet.example_subnet: Refreshing state... [id=ocid1.subnet.oc1.uk-london-1.<rest_of_subnet_ocid>]
oci_core_instance.example_instance: Refreshing state... [id=ocid1.instance.oc1.uk-london-1.<rest_of_instance_ocid>]

OpenTofu used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  - destroy

OpenTofu will perform the following actions:

  # oci_core_instance.example_instance will be destroyed
  - resource "oci_core_instance" "example_instance" {
      - availability_domain  = "Lguh:UK-LONDON-1-AD-3" -> null
      - boot_volume_id       = "ocid1.bootvolume.oc1.uk-london-1.<rest_of_bootvolume_ocid>" -> null
      - compartment_id       = "ocid1.tenancy.oc1.<rest_of_tenancy_ocid>" -> null
      - defined_tags         = {
          - "Oracle-Tags.CreatedBy" = "default/someone@example.com"
          - "Oracle-Tags.CreatedOn" = "2024-09-01T08:55:03.018Z"
        } -> null
      - display_name         = "example_instance" -> null
      - extended_metadata    = {} -> null
      - fault_domain         = "FAULT-DOMAIN-1" -> null
      - freeform_tags        = {} -> null
      - id                   = "ocid1.instance.oc1.uk-london-1.<rest_of_instance_ocid>" -> null
      - image                = "ocid1.image.oc1.uk-london-1.aaaaaaaay6agryw3wg52ruxw56zns3azgwgki3ireaugsuhmfvfnjplxsrfa" -> null
      - is_cross_numa_node   = false -> null
      - launch_mode          = "PARAVIRTUALIZED" -> null
      - metadata             = {} -> null
      - preserve_boot_volume = false -> null
      - private_ip           = "10.0.1.17" -> null
      - region               = "uk-london-1" -> null
      - shape                = "VM.Standard.E2.1.Micro" -> null
      - state                = "RUNNING" -> null
      - subnet_id            = "ocid1.subnet.oc1.uk-london-1.<rest_of_subnet_ocid>" -> null
      - system_tags          = {
          - "orcl-cloud.free-tier-retained" = "true"
        } -> null
      - time_created         = "2024-09-01 08:55:03.616 +0000 UTC" -> null

      - agent_config {
          - are_all_plugins_disabled = false -> null
          - is_management_disabled   = false -> null
          - is_monitoring_disabled   = false -> null
        }

      - availability_config {
          - is_live_migration_preferred = false -> null
          - recovery_action             = "RESTORE_INSTANCE" -> null
        }

      - create_vnic_details {
          - assign_ipv6ip             = false -> null
          - assign_private_dns_record = false -> null
          - assign_public_ip          = "false" -> null
          - defined_tags              = {
              - "Oracle-Tags.CreatedBy" = "default/someone@example.com"
              - "Oracle-Tags.CreatedOn" = "2024-09-01T08:55:03.200Z"
            } -> null
          - display_name              = "instance20240901085503" -> null
          - freeform_tags             = {} -> null
          - nsg_ids                   = [] -> null
          - private_ip                = "10.0.1.17" -> null
          - skip_source_dest_check    = false -> null
          - subnet_id                 = "ocid1.subnet.oc1.uk-london-1.<rest_of_subnet_ocid>" -> null
        }

      - instance_options {
          - are_legacy_imds_endpoints_disabled = false -> null
        }

      - launch_options {
          - boot_volume_type                    = "PARAVIRTUALIZED" -> null
          - firmware                            = "UEFI_64" -> null
          - is_consistent_volume_naming_enabled = true -> null
          - is_pv_encryption_in_transit_enabled = false -> null
          - network_type                        = "PARAVIRTUALIZED" -> null
          - remote_data_volume_type             = "PARAVIRTUALIZED" -> null
        }

      - shape_config {
          - gpus                          = 0 -> null
          - local_disks                   = 0 -> null
          - local_disks_total_size_in_gbs = 0 -> null
          - max_vnic_attachments          = 1 -> null
          - memory_in_gbs                 = 1 -> null
          - networking_bandwidth_in_gbps  = 0.47999998927116394 -> null
          - nvmes                         = 0 -> null
          - ocpus                         = 1 -> null
          - processor_description         = "2.0 GHz AMD EPYC™ 7551 (Naples)" -> null
          - vcpus                         = 2 -> null
        }

      - source_details {
          - boot_volume_size_in_gbs = "47" -> null
          - boot_volume_vpus_per_gb = "10" -> null
          - source_id               = "ocid1.image.oc1.uk-london-1.aaaaaaaay6agryw3wg52ruxw56zns3azgwgki3ireaugsuhmfvfnjplxsrfa" -> null
          - source_type             = "image" -> null
        }
    }

  # oci_core_subnet.example_subnet will be destroyed
  - resource "oci_core_subnet" "example_subnet" {
      - cidr_block                 = "10.0.1.0/24" -> null
      - compartment_id             = "ocid1.tenancy.oc1.<rest_of_tenancy_ocid>" -> null
      - defined_tags               = {
          - "Oracle-Tags.CreatedBy" = "default/someone@example.com"
          - "Oracle-Tags.CreatedOn" = "2024-09-01T08:55:01.287Z"
        } -> null
      - dhcp_options_id            = "ocid1.dhcpoptions.oc1.uk-london-1.<rest_of_dhcpoptions_ocid>" -> null
      - display_name               = "example_subnet" -> null
      - freeform_tags              = {} -> null
      - id                         = "ocid1.subnet.oc1.uk-london-1.<rest_of_subnet_ocid>" -> null
      - ipv6cidr_blocks            = [] -> null
      - prohibit_internet_ingress  = true -> null
      - prohibit_public_ip_on_vnic = true -> null
      - route_table_id             = "ocid1.routetable.oc1.uk-london-1.<rest_of_routetable_ocid>" -> null
      - security_list_ids          = [
          - "ocid1.securitylist.oc1.uk-london-1.<rest_of_securitylist_ocid>",
        ] -> null
      - state                      = "AVAILABLE" -> null
      - time_created               = "2024-09-01 08:55:01.321 +0000 UTC" -> null
      - vcn_id                     = "ocid1.vcn.oc1.uk-london-1.<rest_of_vcn_ocid>" -> null
      - virtual_router_ip          = "10.0.1.1" -> null
      - virtual_router_mac         = "00:00:17:36:D8:6F" -> null
    }

  # oci_core_vcn.example_vcn will be destroyed
  - resource "oci_core_vcn" "example_vcn" {
      - byoipv6cidr_blocks       = [] -> null
      - cidr_block               = "10.0.0.0/16" -> null
      - cidr_blocks              = [
          - "10.0.0.0/16",
        ] -> null
      - compartment_id           = "ocid1.tenancy.oc1.<rest_of_tenancy_ocid>" -> null
      - default_dhcp_options_id  = "ocid1.dhcpoptions.oc1.uk-london-1.<rest_of_dhcpoptions_ocid>" -> null
      - default_route_table_id   = "ocid1.routetable.oc1.uk-london-1.<rest_of_routetable_ocid>" -> null
      - default_security_list_id = "ocid1.securitylist.oc1.uk-london-1.<rest_of_securitylist_ocid>" -> null
      - defined_tags             = {
          - "Oracle-Tags.CreatedBy" = "default/someone@example.com"
          - "Oracle-Tags.CreatedOn" = "2024-09-01T08:55:00.591Z"
        } -> null
      - display_name             = "example_vcn" -> null
      - freeform_tags            = {} -> null
      - id                       = "ocid1.vcn.oc1.uk-london-1.<rest_of_vcn_ocid>" -> null
      - ipv6cidr_blocks          = [] -> null
      - ipv6private_cidr_blocks  = [] -> null
      - is_ipv6enabled           = false -> null
      - state                    = "AVAILABLE" -> null
      - time_created             = "2024-09-01 08:55:00.706 +0000 UTC" -> null
    }

Plan: 0 to add, 0 to change, 3 to destroy.

Do you really want to destroy all resources?
  OpenTofu will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

oci_core_instance.example_instance: Destroying... [id=ocid1.instance.oc1.uk-london-1.<rest_of_instance_ocid>]
oci_core_instance.example_instance: Still destroying... [id=ocid1.instance.oc1.uk-london-1.<rest_of_instance_ocid>, 10s elapsed]
oci_core_instance.example_instance: Still destroying... [id=ocid1.instance.oc1.uk-london-1.<rest_of_instance_ocid>, 20s elapsed]
oci_core_instance.example_instance: Still destroying... [id=ocid1.instance.oc1.uk-london-1.<rest_of_instance_ocid>, 30s elapsed]
oci_core_instance.example_instance: Still destroying... [id=ocid1.instance.oc1.uk-london-1.<rest_of_instance_ocid>, 40s elapsed]
oci_core_instance.example_instance: Still destroying... [id=ocid1.instance.oc1.uk-london-1.<rest_of_instance_ocid>, 50s elapsed]
oci_core_instance.example_instance: Destruction complete after 54s
oci_core_subnet.example_subnet: Destroying... [id=ocid1.subnet.oc1.uk-london-1.<rest_of_subnet_ocid>]
oci_core_subnet.example_subnet: Destruction complete after 0s
oci_core_vcn.example_vcn: Destroying... [id=ocid1.vcn.oc1.uk-london-1.<rest_of_vcn_ocid>]
oci_core_vcn.example_vcn: Destruction complete after 1s

Destroy complete! Resources: 3 destroyed.
$ 
```

If we change our mind and decide we want this infrastructure recreated, then it's a simple case
of running `tofu apply` again.
