####### Variables for resource groups
variable "rg-frontdoor" {
  description = "Resource Group for Frontdoor"
  type        = string
  default     = "FD-Microhack-Frontdoor"
}

variable "rg-storageaccount" {
  description = "Resource Group for Frontdoor"
  type        = string
  default     = "FD-Microhack-storage"
}

variable "rg-pl-vm-backend" {
  description = "Resource Group for PrivateLink Backend"
  type        = string
  default     = "FD-Microhack-pl-vm-backend"
}

variable "rg-webserver" {
  description = "Resource Group for webservers in different regions"
  type        = string
  default     = "FD-Microhack-webserver"
}

###### Variables for locations
variable "location-bastion-network" {
  description = "location of Azure bastion"
  type        = string
  default     = "westeurope"
}

variable "location-storagaccount1" {
  description = "Resource Group for Frontdoor"
  type        = string
  default     = "westeurope"
}

variable "location-storagaccount2" {
  description = "Resource Group for Frontdoor"
  type        = string
  default     = "centralus"
}

variable "location-storagaccount3" {
  description = "Resource Group for Frontdoor"
  type        = string
  default     = "southeastasia"
}

variable "frontdoorstdname" {
  description = "Name of Frontdoor standard"
  type        = string
  default     = "fds"
}

variable "frontdoorstdlocation" {
  description = "Location of FrontDoor Standard"
  type        =  string
  default     = "westeurope"
}


variable "location-client-southeastasia" {
  description = "Location to deploy client in SEA"
  type        = string
  default     = "SouthEastAsia"
}

variable "location-client-uscentral" {
  description = "Location to deploy client in USCentral"
  type        = string
  default     = "centralus"
}

variable "location-client-westeurope" {
  description = "Location to deploy client in westeurope"
  type        = string
  default     = "westeurope"
}

variable "location-frontdoor" {
  description = "Location to deploy frontdoor"
  type        = string
  default     = "WestEurope"
}

variable "location-pl-backend-eastus" {
  description = "Location to deploy we hub"
  type        = string
  default     = "EastUS"
}

variable "username" {
  description = "Username for Virtual Machines"
  type        = string
  default     = "mhackadmin"
}

variable "password" {
  description = "Virtual Machine password, must meet Azure complexity requirements"
   type        = string
   default     = "Microhack2020"
}

variable "vmsize" {
  description = "Size of the VMs"
  default     = "Standard_B1s"
}

variable "vmsize-windows" {
  description = "Size of the windows VMs"
  default     = "Standard_B2ms"
}


variable "resource_tags" {
  description = "Tags to set for all resources"
  type        = map(string)
  default     = {
    environment = "webserver"
    deployment  = "terraform"
    microhack    = "frontdoor"
  }
}


#############################################################

variable "prefix" {
  description = "(Required) Default prefix to use with your resource names."
  type        = string
  default     = "azure_lb"
}

variable "remote_port" {
  description = "Protocols to be used for remote vm access. [protocol, backend_port].  Frontend port will be automatically generated starting at 50000 and in the output."
  type        = map(any)
  default     = {}
}

variable "lb_port" {
  description = "Protocols to be used for lb rules. Format as [frontend_port, protocol, backend_port]"
  type        = map(any)
  default     = {}
}

variable "lb_probe_unhealthy_threshold" {
  description = "Number of times the load balancer health probe has an unsuccessful attempt before considering the endpoint unhealthy."
  type        = number
  default     = 2
}

variable "lb_probe_interval" {
  description = "Interval in seconds the load balancer health probe rule does a check"
  type        = number
  default     = 5
}

variable "frontend_name" {
  description = "(Required) Specifies the name of the frontend ip configuration."
  type        = string
  default     = "myPublicIP"
}

variable "allocation_method" {
  description = "(Required) Defines how an IP address is assigned. Options are Static or Dynamic."
  type        = string
  default     = "Static"
}

variable "tags" {
  type = map(string)

  default = {
    source = "terraform"
  }
}

variable "type" {
  description = "(Optional) Defined if the loadbalancer is private or public"
  type        = string
  default     = "public"
}

variable "frontend_subnet_id" {
  description = "(Optional) Frontend subnet id to use when in private mode"
  type        = string
  default     = ""
}

variable "frontend_private_ip_address" {
  description = "(Optional) Private ip address to assign to frontend. Use it with type = private"
  type        = string
  default     = ""
}

variable "lb_sku" {
  description = "(Optional) The SKU of the Azure Load Balancer. Accepted values are Basic and Standard."
  type        = string
  default     = "Standard"
}

variable "lb_probe" {
  description = "(Optional) Protocols to be used for lb health probes. Format as [protocol, port, request_path]"
  type        = map(any)
  default     = {}
}

variable "name" {
  description = "(Optional) Name of the load balancer. If it is set, the 'prefix' variable will be ignored."
  type        = string
  default     = ""
}