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
sudo dnf install -y tofu
```
(I substituted `dnf` for `yum` but using `yum` probably works equally well.)

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

There are a number of different ways that you can authenticate to OCI to make changes. One of 
the easiest is to use 
[token-based authentication](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/clitoken.htm).
This has the advantage that you don't need to store security sensitive information in your 
OpenTofu configuration files. To use token-based authentication you use the `oci` CLI as follows:

```shell
oci session authenticate
```

This first prompts you for the region that you want to connect to. You can use either the [region 
identifier](https://docs.oracle.com/en-us/iaas/Content/General/Concepts/regions.htm), e.g. 
uk-london-1, or pick the number of the region from the given list:

```ignorelang
$ oci session authenticate
Enter a region by index or name(e.g.
1: af-johannesburg-1, 2: ap-chiyoda-1, 3: ap-chuncheon-1, 4: ap-dcc-canberra-1, 5: ap-dcc-gazipur-1,
6: ap-hyderabad-1, 7: ap-ibaraki-1, 8: ap-melbourne-1, 9: ap-mumbai-1, 10: ap-osaka-1,
11: ap-seoul-1, 12: ap-singapore-1, 13: ap-sydney-1, 14: ap-tokyo-1, 15: ca-montreal-1,
.
.
.
51: uk-gov-london-1, 52: uk-london-1, 53: us-ashburn-1, 54: us-chicago-1, 55: us-gov-ashburn-1,
56: us-gov-chicago-1, 57: us-gov-phoenix-1, 58: us-langley-1, 59: us-luke-1, 60: us-phoenix-1,
61: us-saltlake-2, 62: us-sanjose-1): 
```

a browser session is then launched to log into OCI. Once complete the browser session tells you 
it can be closed:

```ignorelang
Authorization completed! Please close this window and return to your terminal to finish the bootstrap process.
```

When you go back to your CLI session, you can see that the `oci` command prompts you for a profile 
name to use for this session (here I entered uk-london-1 as the region identifier to use):

```ignorelang
.
.
.
61: us-saltlake-2, 62: us-sanjose-1): uk-london-1
    Please switch to newly opened browser window to log in!
    You can also open the following URL in a web browser window to continue:
https://login.uk-london-1.oraclecloud.com/v1/oauth2/authorize?action=login&client_id=iaas_console&response_type=token+id_token&nonce=fdbf2256-9fb4-4577-b18d-7015d4b6b4e7&scope=openid&public_key=eyJrdHkiOiAiUlNBIiwgIm4iOiAicnVhaTlBQlNQcGJZemlxMlhabmV1TDFldVRHVW9CcFZRWmVxcXVFWkFwcGRoU25WNDVPVlo0a1pNRnZCb3dZdGRHSGlyLThNb1l0MkVTOWZFNGF3ZFBkVlJ5anlfU2VwNzBZSTZHWW8xTFA0UVFRQXlLU2F5TS1WTm5VODNES25Fd0tiQUFfX2VWekFxTFRXNGpzVkI4SXJtSUZkZkI2c1ppSjY5M2dyZUwwQnFFcGxtQ1hMRTA3UHZwMC1udGVUZGpJZHNwNnFBU0czOWJwd2tVNUZNRDRVRDlCN2plMTBMOTFZSExPenVZdHRISXo3ekRPTEREWllDMC1zM3E5YVVvZUoyWkJQNUxNVjdsV3ZWT05oekVMQ1dHU05pSk1BLXB6NUtIeUJUMTlpT19ZMnVvek90WFZOUFNqZldHMnpXN0lYMmh5WVFOQWhSSFpZeE5WRXJRIiwgImUiOiAiQVFBQiIsICJraWQiOiAiSWdub3JlZCJ9&redirect_uri=http%3A%2F%2Flocalhost%3A8181
    Completed browser authentication process!
Enter the name of the profile you would like to create:
```

Here I entered DEFAULT as the profile name:

```ignorelang
.
.
.
Enter the name of the profile you would like to create: DEFAULT
Config written to: /home/stephen/.oci/config

    Try out your newly created session credentials with the following example command:

    oci iam region list --config-file /home/stephen/.oci/config --profile DEFAULT --auth security_token

$
```

To test that you are connected, you can try running the command given to get the current region 
list from the Identification and Access Management (IAM) service. In my case running that 
command gives:

```ignorelang
$ oci iam region list --config-file /home/stephen/.oci/config --profile DEFAULT --auth security_token
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

By default a session token is valid for 1 hour. You can refresh the token using the `oci` command:

```shell
oci session refresh --profile <profile_name>
```