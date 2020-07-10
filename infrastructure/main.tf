terraform {
  backend "azurerm" {}
}

provider "azurerm" {
  version = "~> 2.16.0"
  features {}
}

locals {
  vault_name                 = "${var.product}-${var.env}"
  default_external_host_name = "idam-web-public.${replace(var.env, "idam-", "")}.platform.hmcts.net"
  env                        = "${var.env == "idam-preview" && var.product == "idam" ? "idam-dev" : var.env}"
  tags                       = "${merge(var.common_tags, map("environment", local.env))}"
  redis_enabled              = "${lookup(var.redis_enabled, var.env)}"
}

data "azurerm_virtual_network" "idam" {
  name                = "core-infra-vnet-${var.env}"
  resource_group_name = "core-infra-${var.env}"
}

data "azurerm_subnet" "redis" {
  name                 = element(data.azurerm_virtual_network.idam.subnets, 3)
  virtual_network_name = data.azurerm_virtual_network.idam.name
  resource_group_name  = "core-infra-${var.env}"
}

data "azurerm_key_vault" "idam" {
  name                = local.vault_name
  resource_group_name = "idam-${var.env}"
}

module "redis-cache" {
  count       = local.redis_enabled
  source      = "git@github.com:hmcts/cnp-module-redis?ref=master"
  product     = "idam-web-public"
  location    = var.location
  env         = var.env
  subnetid    = data.azurerm_subnet.redis.id
  common_tags = var.common_tags
}

resource "azurerm_key_vault_secret" "redis_hostname" {
  count        = local.redis_enabled
  name         = "redis-hostname"
  value        = module.redis-cache.host_name
  key_vault_id = data.azurerm_key_vault.idam.id
}

resource "azurerm_key_vault_secret" "redis_port" {
  count        = local.redis_enabled
  name         = "redis-port"
  value        = module.redis-cache.redis_port
  key_vault_id = data.azurerm_key_vault.idam.id
}

resource "azurerm_key_vault_secret" "redis_key" {
  count        = local.redis_enabled
  name         = "redis-key"
  value        = module.redis-cache.access_key
  key_vault_id = data.azurerm_key_vault.idam.id
}