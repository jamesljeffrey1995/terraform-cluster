provider "azurerm" {
  features {}
}

module "UK_Group" {
  source = "./build_module"
  rgname = "uk-group"
  location = "uksouth"
  timezone = "GMT Standard Time"
  start_time = [9]
  stop_time = [17]
  env    = "development"
}

module "FRN_Group" {
  source = "./build_module"
  rgname = "france-group"
  location = "FranceCentral"
  timezone = "Central European Summer Time"
  start_time = [10]
  stop_time = [15]
  env    = "staging"
}

module "ASA_Group" {
  source = "./build_module"
  rgname = "asia-group"
  location = "KoreaCentral"
  timezone = "Korean Standard Time"
  start_time = [2]
  stop_time = [10]
  env    = "production"
}
