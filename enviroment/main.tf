resource "azurerm_resource_group" "Terraform" {

  name     = var.resname
  location = var.location
}

resource "azurerm_virtual_network" "virtnet" {
  name                = "${var.location}-vn"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.Terraform.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "uksub"
  resource_group_name  = azurerm_resource_group.Terraform.name
  virtual_network_name = azurerm_virtual_network.virtnet.name
  address_prefixes     = ["10.0.2.0/24"]
}


resource "azurerm_virtual_machine_scale_set" "scaleset" {
  name                = "${var.location}-scaleset-1"
  location            = var.location
  resource_group_name = azurerm_resource_group.Terraform.name
  
  upgrade_policy_mode  = "Manual"

  
  sku {
    name     = "Standard_F2"
    tier     = "Standard"
    capacity = 1
  }

  storage_profile_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_profile_data_disk {
    lun           = 0
    caching       = "ReadWrite"
    create_option = "Empty"
    disk_size_gb  = 10
  }

  os_profile {
    computer_name_prefix = "${var.location}-vm"
    admin_username       = "myadmin"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/myadmin/.ssh/authorized_keys"
      key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDYxj4uMT/8fJeS3Vh2U10divlE/ptuQbDl+irE9QVtpKZdewpuo8nNKqr++oFB1olPnI0Xb+IUfn1/zTzYW+WJS9goFcRhi9g96tROKhWHJqwik8gMrl4VlbnPCzKtEobCn1x1NbA7nanX8eXNLY9W0cD9mhLGoojIiiS8UBgrLz2GdSx6tpw0uld32amdzLkn7x0nn2k3cnosyiU5MTXLvc91DDitqd9OeA8uG/h7JC+YWcVl4jj3/BicL6UGPZo2dyOshTbdSGt+9DTPKwZS1jNg6dHNwK5K3WSHMrfGzgoojelN/wRZL8yYI2EwiT7RNtuBAtuSNvrCMxACXL0B JamesJeffrey@vm"
    }
  }

  network_profile {
    name    = "terraformnetworkprofile"
    primary = true

    ip_configuration {
      name                                   = "${var.location}-IPConfiguration"
      primary                                = true
      subnet_id                              = azurerm_subnet.subnet.id
    }
  }

  tags = {
    environment = "${var.env}"
  }
}

resource "azurerm_monitor_autoscale_setting" "autoscale" {
  name                = "myAutoscaleSetting"
  resource_group_name = azurerm_resource_group.Terraform.name
  location            = var.location
  target_resource_id  = azurerm_virtual_machine_scale_set.scaleset.id

  profile {
    name = "startProfile"

    capacity {
      default = 1
      minimum = 1
      maximum = 3
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_virtual_machine_scale_set.scaleset.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_virtual_machine_scale_set.scaleset.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

    recurrence {
      timezone  = var.timezone
      days      = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
      hours     = var.start_time
      minutes   = [0]
    }
   }
  
  profile {
    name = "stopProfile"

    capacity {
      default = 0
      minimum = 0
      maximum = 0
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_virtual_machine_scale_set.scaleset.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_virtual_machine_scale_set.scaleset.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
    recurrence {
      timezone  = var.timezone
      days      = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
      hours     = var.stop_time
      minutes   = [0]
    }
    }
} 
