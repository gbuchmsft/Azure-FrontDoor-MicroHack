# Microhack : Using Azure FrontDoor to expose Workloads to the Internet

# Contents

[About Microhacks](#about-microhacks)

[Overview](#overview)

[Environment](#environment)

[Create Environment](#create-environment)

[Configure diagnostic settings](#configure-diagnostic-settings)

[Configure TLS encryption on Webserver](#configure-tls-encryption-on-webserver)

[Module 0 : Check the environment](#module-0--check-the-environment)

[Module 1 : Explore FrontDoor backend options](#module-1--explore-frontdoor-backend-pool-options)

[Module 2 : Explore FrontDoor routing rules](#module-2--explore-frontdoor-routing-rules)

[Module 3 : (optional) Add your own domain](#module-3--optional-add-your-own-domain)

[Closing : Clean up resources](#closing--clean-up-resources)

**Work in progress / coming soon:**
*Module x : Monitoring Azure FrontDoor*
*Module x : Azure FrontDoor Premium*
*Module x : Accessing FrontDoor via IPv6*
*Module x : Test failover of backend member*
*Additional information*
*Adopt the environment to your needs*

---


## About Microhacks
Microhacks are a great way to explore a certain topic in a short amount of time. They're purpose build and helps you to get a basic understanding of a service without overwhelming you with the complexity of the documentation. Instead you're going to use a pre-build environment and use this to learn and gather your own findings.
This pre-build environment is also useful if you want to test something or need to build a lab environment.

Besides this Microhack, there are a couple of others available:

- Azure virtual WAN https://github.com/mddazure/azure-vwan-microhack
- Azure Private Link https://github.com/adstuart/azure-privatelink-dns-microhack

## Overview
In this Microhack you're going to learn about the different options in Azure FrontDoor and how it can help to deliver high available and securel Applications to the Internet.
Beginning with a Standard FrontDoor instance, you're going to learn about the different backend options, explore request routing in Azure FD and see the rules engine in action.

Moving on, you'll create an Azure FrontDoor Premium and deploy a backend connected via private link (this feature ist still in preview but quite interesting for many scenarios).

## Environment
Since deployment of the necessary resources takes some time, many parts of the lab enviroment are scripted and deployment can be done via terraform.


### Backends
FrontDoor is a global service and can forward requests to backends based on different algorithms.
To see the different options, we're going to deploy storage accounts, containing static website content and webservers in different regions.

If you're using the supplied scripts, backends will be deployed in:

- West Europe (WEU)
- US Central (USC)
- SouthEast Asia (SEA)

<img src="resources/T0-backends.png" width="400">


### Clients
To simulate access from different regions, we'll deploy VMs in three different regions. These VMs will be used to connect to Azure FrontDoor and to observe how Azure FrontDoor handles requests from different regions. The client VMs will be deployed in the same regions as the backends are deployed.

The clients are based on Windows Server 2019.

<img src="resources/T0-Clients.png" width="400">

Clients can be accessed via RDP or Azure Bastion. The terraform script automatically added the client IP address from the deployment environment to the allowed RDP hosts in the Network Security Group.

Ensure that your client IP-Address is added and that your firewall allows port 3389 (RDP) outbound. If not, please use Azure Bastion.


## Create Environment
When you're using your local environment, be sure that you have the latest versions of AZ-CLI, a git client and terraform installed.
For now, I'm going to assume that you'll be using [Azure Cloud Shell](https://docs.microsoft.com/en-us/azure/cloud-shell/overview)

- Log in to Azure Cloud Shell at https://shell.azure.com/ and select Bash
  
- Ensure Azure CLI and extensions are up to date:
    ```console
  az upgrade --yes
  ```  
- Verify you're using the right subscription:
  ```console
  az account list -o table | grep True
  ```
- If not, change to the suscription you want to use for the deployment:
  ```console
  az account set --subscription <Name or ID of subscription>
  ```
  
- Clone this github repository. Go to the local directory where the github repo shall be cloned to and issue:
  ```console
  git clone https://github.com/gbuch/azure-frontdoor-microhack
  ```

- Change directory:
  ```console
  cd ./azure-frontdoor-microhack
  ```

- Initialize terraform and download the azurerm resource provider:
  ```console
  terraform init
  ```
- Now start the deployment (when prompted, confirm with **yes** to start the deployment):
  ```console
  terraform apply
  ```

Make Note of the output variables after the deployment finished.

But no worries, even if you haven't noted the variables, you can always show them by issuing the command:
```console
terraform output
```

The following output variables are exposed from terraform at the end of the deployment:

AzureFrontDoorName = This is the name of the FrontDoor in Azure. It's a random name.
AzureFrontDoorNameCNAME = This is the URL of the FrontDoor.
AzureVM-WEU-fqdn = "cltweu-9033.westeurope.cloudapp.azure.com"
VM-Webserver-SEA = IP-Address of Webserver SEA
Virtual_Machine-SEA = IP-Address of Client-VM in SEA
Virtual_Machine-USC = IP-Address of Client-VM in USC
Virtual_Machine-USC-PW = Password for all Virtual Machines*
Virtual_Machine-WEU = IP-Address of Client-VM in WEU
Webserver_SEA = FQDN of webserver in SEA
Webserver_USC = FQDN of webserver in USC
Webserver_WEU = FQDN of webserver in WEU
azurerm_storage_account_web_endpoint = "https://seae21ef0a54b2bf70e.z23.web.core.windows.net/"
azurerm_storage_account_web_host = "seae21ef0a54b2bf70e.z23.web.core.windows.net"

* I've decided to put the VM password in the console output, in a lab, this is quite convenient. Please keep in mind to NOT DO THIS IN PRODUCTION ! Also, since Terraform 0.15, these output will be omitted as insecure, but I decided to use the nonsensitive()-function to override the warning.

## Configure diagnostic settings
Later in this Microhack, you'll take a deeper look into monitoring your FrontDoor instance and eg. check backend availability. So you need to configure diagnostic settings accordingly.

Although this can also be done via terraform, there's a risk of using a "wrong" log analytics workspace. So decision was to configure it manually.

To start feeding data into the log analytics workspace, go to the FrontDoor resource created in the Resource-Group "FD-Microhack-Frontdoor" (unless you changed it in the variables.tf) and open the "Diagnostic settings".


<img src="resources/Diagnostic%20settings.png" width=800>

After hitting "edit setting", you change the diagnostic settings according to this:

<img src="resources/DiagnosticSettings2.png" width=800>

Now, the data will be injected into Log Analytics for further analysis.

## Configure TLS encryption on Webserver

In this task, you're going to create a public TLS Certificates using Let's Encrypt certificates.
The public certificates are needed because Azure FrontDoor will only communicate with backend pool members that have a valid TSL certificate.
You're allowed to login to the VMs that host the NGINX Webservers via SSH (the IP from the client you used for deployment is allowed in the NSG for SSH. Caution: If you used CloudShell for deployment, you need to add your public IP, from where you want to SSH in, to the NSG).
Please open a console and connect to the VM:

```console
ssh mhackadmin@FQDN-OF-WEBSERVER
```
Use the PW shown in the terraform deployment output.

First you need to uncomment "server_names_hash_bucket_size" in the /etc/nginx/nginx.conf file and increase the value from 64 to 128.

After you've edited the file, you need to restart nginx : 
```console
sudo nginx -s reload
```

Next you're going to create a Let's encrypt certificate to enable TLS on the webserver.

```console
sudo certbot --nginx -d FQDN-OF-WEBSERVER --register-unsafely-without-email --agree-tos --no-redirect
```

:exclamation: A note on using Let's encrypt certificates

Let's encrypt is a free CA that allows you to create free TLS certificates. While encryption in general is a great Idea, and Let's encrypt has made the web signicantly safer by providing TLS encryption for everyone, there are certain gotchas with this.
So, it's OK to use it for this Lab, if you're going to deploy this in a production environment, you may consider using a commercial alternative (depending on your needs).

## Module 0 : Check the environment
There are a few checks that you can use to confirm that the environment is working as expected.
- [ ] Check connectivity to Storage Accounts using a webbrowser
- [ ] Check direct connecivity to webservers using a webbrowser
- [ ] Check connectivity to clients via RDP or Bastion
- [ ] Check connectivity to webservers via SSH or Bastion

## Module 1 : Explore FrontDoor backend pool options

FrontDoor Standard offers a wide variety of services that can be used in a backend pool. All of the backend pool options are based on public reachable targets (one of the advantages of FrontDoor Premium, that offers options for private backends).

After you've checked the environment, you can start to explore the FrontDoor backends that has been created by the terraform deployment.


Two backend pools have been created by the terraform script.

1. Backend-Storage
   
   If you have static content, that's a very attractive option since you can use an Azure storage account as backend. The storage account must be configured accordingly : [Static website hosting in Azure Storage](https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blob-static-website)
   
   Storage accounts are located in different Azure regions to see different routing.

2. Backend-Webserver
   
   Webservers are based on Nginx and are deployed in three different Azure Regions. The backend host type is "Custom host" and uses the FQDN of each individual VM.
<img src="resources/backend-pool-1.png" width=400>

A backend pools can consist of different backends, eg. you can have a backend pool with a storage account and a custom host.

Task : Add a new backend to the pool. Ensure that you're using a different type. Eg. add a webserver to the "Backend-Storage" pool.

- What is the result ?
- Is there any difference ?
- What is if you're accessing FrontDoor from a different region ?

Each backend pool member has additional configuration options. It can be enabled/disabled (taking requests or not), you can configure a backend host header (if you host multiple sites on a single webserver) and you can set a priority (eg. lower priority (higher number) could be used to create a backend pool member that is used for backup). In addition, you can set a weight, to distribute traffic unequally to the backend pool members.

Task : Test the behaviour if you change the priority or the latency.
- What did change in the behaviour ?

You should now have a basic understanding of backend pools, including members and traffic distribution.


## Module 2 : Explore FrontDoor routing rules
FrontDoor consists of backend pools, which contain the "destinations" and what we explored earlier, and routing rules. Routing rules are a basic instrument to destine where incoming traffic is routed to and how.

The deployment created one routing rule ("Routing-Rule-1") that sends all incoming traffic to the backend pool "Backend-Storage". It also ensures that only HTTPS is forwarded.
You can use routing rules to route traffic to different backend pools based on the URI path. Eg. send all traffic coming in on https://F.Q.D.N/images to a backend pool that just serving images.

<img src="resources/routing-rules-1.png" width=400>

Task :
- Create a new routing rule that sends all traffic, coming in on https://F.Q.D.N/webserver to the "Backend-Webserver"-pool.
- Try the different options for "Forward" and "Redirect" and see how they work

- What did you explore ? Try to explain why.
- In which deployments is this helpful ?

## Module 3 : (optional) Add your own domain
Of course you can use the Microsoft supplied name for the Azure Frontdoor which is NAME.azurefd.net . But mostlikely you would like to have something that adheres to your company. While you're free to use something like MYCOMPANY.azurefd.net (as long as the name is not already taken), it's still not the best option and you surely would like to use your own domain name.

That option is also available in Azure FrontDoor and good news, it's quite comfortable because you could include a managed TLS certificate (or you could use your own certificate).

As mentioned, adding your custom domain name is quite easy. Simply follow these steps:
- Click the (+) sign on "Frontends/domains"
  <img src="resources/bring-your-own-domain-1.png" width=430> 
  <br />
- Enter the "Custom host name" that you want to add eg. fdmicrohack.azure.HIDDEN.de
- Add a CNAME record to your DNS hosting the domain that you want to add, according to the data shown in the configuration of the custom domain. If your using Azure DNS it looks similar to this:<br />
  <img src="resources/bring-your-own-domain-2-dns.png" width=430>

  Notice the warning :
  <img src="resources/bring-your-own-domain-3-rule.png" width=600>
  This means, that you haven't added the new domain to a routing rule. To fix this you need to either modify a routing rule to include the domain, or create a new routing rule. In the routing rule, you'll need to set/add 
  the frontends/domains.

  <img src="reources/../resources/bring-your-own-domain-4.png" width=460>
  
  Wasn't that easy ?

 # Closing : Clean up resources
After finishing the Microhack, you want to clean up your subscription to save costs.
Just go back to the console our cloudshell and issue the following command:
```console
terraform destroy
```
You might want to check that the resource group is deleted afterwards, if not, please delete it.



# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
You're leaving the "finish line". Everything below this line is work in progress
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+