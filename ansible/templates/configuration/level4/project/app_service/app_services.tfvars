# features
# -------------------------
# application app_insights
# monitor_autoscale_settings
# storage_account
# backup
# logs
# diagnostic settings


# By default asp1 will inherit from the resource group location
app_service_plans = {
  asp1 = {
    resource_group_key = "webapp_rg_re1"
    name               = "asp-webapp"

    maximum_elastic_worker_count = 5

    sku = {
      tier = "Standard"
      size = "S1"
    }
  }
}

app_services = {
  webapp1 = {
    resource_group_key   = "webapp_rg_re1"
    name                 = "webapp-dot-net"
    app_service_plan_key = "asp1"
    application_insight_key = "app_insights1"

    # outbound access - vnet ingration: vnet_spoke_internet_re1 - outbound subnet: web_internet_subnet 
    vnet_integration = {

{% if gcc_platform | trim == '1' %}
      subnet_id = "/subscriptions/{{subscription_id}}/resourceGroups/{{resource_group_name}}/providers/Microsoft.Network/virtualNetworks/{{internet_vnet_name}}/subnets/{{prefix}}-snet-web-internet"
{% else %}
      vnet_key = "vnet_spoke_internet_re1"
      subnet_key = "web_internet_subnet"
      lz_key = "networking_spoke_internet"    
      # subnet_id = "/subscriptions/{{subscription_id}}/resourceGroups/{{resource_group_name}}/providers/Microsoft.Network/virtualNetworks/{{internet_vnet_name}}/subnets/{{prefix}}-snet-web-internet"
{% endif %}

    }

    diagnostic_profiles = {
      central_logs_region = {
        definition_key   = "app_service"
        destination_type = "log_analytics"
        destination_key  = "central_logs"
        lz_key = "shared_services" # TODO: is this required?
      }
    }  

    # diagnostic_profiles = {
    #   app_service = {
    #     definition_key   = "app_service"
    #     destination_type = "log_analytics"    
    #     destination_key  = "central_logs"            
    #     # destination_type = "event_hub"
    #     # destination_key  = "central_logs_example" 
    #   }
    # }

    tags = { 
      purpose = "internet app service" 
      project-code = "{{project_code}}" 
      env = "{{caf_environment}}" 
      zone = "{{zone_code}}"
      tier = "{{tier_code}}"        
    }     

    # Optional: inbound access - enabled private endpoint - private endpoint name - inbound subnet - private dns 
    private_endpoints = {
      # Require enforce_private_link_endpoint_network_policies set to true on the subnet
      pe1_webapp = {
        name       = "pep-web-app"

        vnet_key = "vnet_spoke_internet_re1"
        subnet_key = "app_internet_subnet"
        lz_key = "networking_spoke_internet"    
        # subnet_id = subnet_id = "/subscriptions/{{subscription_id}}/resourceGroups/{{resource_group_name}}/providers/Microsoft.Network/virtualNetworks/{{internet_vnet_name}}/subnets/{{prefix}}-snet-web-internet"

        resource_group_key = "webapp_rg_re1"

        private_service_connection = {
          name                 = "psc-webapp"
          is_manual_connection = false
          subresource_names    = ["sites"]
        }

        # private_dns = {
        #   zone_group_name = "default"
        #   lz_key          = "networking_spoke_internet" # if DNS keys is deployed in remote landingzone
        #   keys = ["webapp_dns_re1"]
        # }
      }
    }

    app_settings = {
      "WEBSITE_NODE_DEFAULT_VERSION" = "6.9.1"
      "Example" = "Extend",
      "LZ"      = "CAF"
    }

    identity = {
      type = "SystemAssigned"
    }

    settings = {
      enabled = true

      client_affinity_enabled = false
      client_cert_enabled     = false
      https_only              = false

      # # window app
      # site_config = {
      #   number_of_workers        = 2
      #   default_documents        = ["main.aspx"]
      #   always_on                = true
      #   dotnet_framework_version = "v7.0" # "v4.0"
      #   app_command_line         = null         ///sbin/myserver -b 0.0.0.0
      #   ftps_state               = "AllAllowed" //AllAllowed, FtpsOnly and Disabled
      #   http2_enabled            = false
      # }

      tags = { 
        purpose = "internet app service webapp1" 
        project-code = "{{project_code}}" 
        env = "{{caf_environment}}" 
        zone = "{{zone_code}}"
        tier = "{{tier_code}}"        
      } 

      backup = {
        name                = "webapp_backup"
        enabled             = true
        storage_account_key = "sa_backup"
        container_key       = "backup"
        //storage_account_url = "https://cindstsabackup.blob.core.windows.net/webapp-backup?sv=2018-11-09&sr=c&st=2021-02-08T07%3A07%3A42Z&se=2021-03-10T07%3A07%3A42Z&sp=racwdl&spr=https&sig=5LX%2ByDoE4YQsf%2F0L5f42eML9mk%2Fu5ejjZYVIs81Keng%3D"

        sas_policy = {
          expire_in_days = 30
          rotation = {
            #
            # Set how often the sas token must be rotated. When passed the renewal time, running the terraform plan / apply will change to a new sas token
            # Only set one of the value
            #

            # mins = 1 # only recommended for CI and demo
            days = 7
            # months = 1
          }
        }

        schedule = {
          frequency_interval       = 1
          frequency_unit           = "Day"
          keep_at_least_one_backup = true
          retention_period_in_days = 1
          start_time               = "2023-11-08T00:00:00Z"
        }
      }

      logs = {
        application_logs = {
          file_system_level = "Error" # can be Warning, Information, Verbose or Off
          azure_blob_storage = {
            level             = "Error" # can be Warning, Information, Verbose or Off
            retention_in_days = 60
          }
        }

        detailed_error_messages_enabled = true
        failed_request_tracing_enabled  = true

        # lz_key = ""  # if in remote landingzone
        storage_account_key = "sa_logs"
        container_key       = "logs"

        sas_policy = {
          expire_in_days = 30
          rotation = {
            #
            # Set how often the sas token must be rotated. When passed the renewal time, running the terraform plan / apply will change to a new sas token
            # Only set one of the value
            #

            # mins = 1 # only recommended for CI and demo
            days = 7
            # months = 1
          }
        }

        http_logs = {
          azure_blob_storage = {
            retention_in_days = 30
          }

          #
          # Either azure_blob_storage or file_system can be used but not both at the same time
          #

          # file_system = {
          #   retention_in_days = 30
          #   retention_in_mb   = 2
          # }

          storage_account_key = "sa_logs"
          container_key       = "http_logs"
          sas_policy = {
            expire_in_days = 30
            rotation = {
              #
              # Set how often the sas token must be rotated. When passed the renewal time, running the terraform plan / apply will change to a new sas token
              # Only set one of the value
              #

              # mins = 1 # only recommended for CI and demo
              days = 7
              # months = 1
            }
          }
        }

      }      

    }


  }
}

storage_accounts = {
  sa1 = {
    name                     = "sa1dev"
    resource_group_key       = "webapp_rg_re1"
    account_kind             = "BlobStorage"
    account_tier             = "Standard"
    account_replication_type = "LRS"

    containers = {
      sc1 = {
        name = "sc1"
      }
    }
  }
  # sa2 = {
  #   name                     = "sa2dev"
  #   resource_group_key       = "webapp_rg_re1"
  #   account_kind             = "FileStorage"
  #   account_tier             = "Premium"
  #   account_replication_type = "LRS"
  #   min_tls_version          = "TLS1_2"
  #   large_file_share_enabled = true

  #   file_shares = {
  #     fs1 = {
  #       name  = "fs1"
  #       quota = "100"
  #     }
  #   }
  # }

  sa_backup = {
    name               = "sa-backup"
    resource_group_key = "webapp_rg_re1"
    # Account types are BlobStorage, BlockBlobStorage, FileStorage, Storage and StorageV2. Defaults to StorageV2
    account_kind = "BlobStorage"
    # Account Tier options are Standard and Premium. For BlockBlobStorage and FileStorage accounts only Premium is valid.
    account_tier = "Standard"
    #  Valid options are LRS, GRS, RAGRS, ZRS, GZRS and RAGZRS
    account_replication_type = "LRS" # https://docs.microsoft.com/en-us/azure/storage/common/storage-redundancy
    containers = {
      backup = {
        name = "webapp-backup"
      }
    }
  }
  sa_logs = {
    name               = "sa-logs"
    resource_group_key = "webapp_rg_re1"
    # Account types are BlobStorage, BlockBlobStorage, FileStorage, Storage and StorageV2. Defaults to StorageV2
    account_kind = "BlobStorage"
    # Account Tier options are Standard and Premium. For BlockBlobStorage and FileStorage accounts only Premium is valid.
    account_tier = "Standard"
    #  Valid options are LRS, GRS, RAGRS, ZRS, GZRS and RAGZRS
    account_replication_type = "LRS" # https://docs.microsoft.com/en-us/azure/storage/common/storage-redundancy
    containers = {
      logs = {
        name = "webapp-logs"
      }
      http_logs = {
        name = "webapp-http-logs"
      }
    }
  }

}

azurerm_application_insights = {
  app_insights1 = {
    name               = "appinsights-webapp"
    resource_group_key = "webapp_rg_re1"
    application_type   = "web"
  }
}

monitor_autoscale_settings = {
  mas1 = {
    name               = "mas1-webapp"
    enabled            = true
    resource_group_key = "webapp_rg_re1"

    target_resource = {
      # lz_key = ""
      # vmss_key = ""
      app_service_plan_key = "asp1"
    }

    profiles = {
      profile1 = {
        name = "profile1"

        capacity = {
          default = 1
          minimum = 1
          maximum = 3
        }

        rules = {
          rule1 = {
            metric_trigger = {

              # metric_name = "Percentage CPU" # vmss uses this
              # You can also choose your resource id manually, in case it is required
              # metric_resource_id = "/subscriptions/manual-id"
              metric_name      = "CpuPercentage"
              metric_namespace = "microsoft.web/serverfarms"
              time_grain       = "PT1M"
              statistic        = "Average"
              time_window      = "PT10M"
              time_aggregation = "Average"
              operator         = "GreaterThan"
              threshold        = 70
              # You can optionally fill the following fields

              # divide_by_instance_count = true

              # dimensions = {
              #   dimension1 = {
              #     name     = "App1"
              #     operator = "Equals"
              #     values   = []
              #   }

              # }

            }
            scale_action = {
              direction = "Increase"
              type      = "ChangeCount"
              value     = "1"
              cooldown  = "PT5M"
            }

          }
        }

      }
    }

  }
}

# # unable to use the one in shared service remote lz - create locally
# # For diagnostic settings
# diagnostics_definition = {
#   app_service = {
#     name = "operational_logs_and_metrics"

#     categories = {
#       log = [
#         #["Category name",  "Diagnostics Enabled(true/false)", "Retention Enabled(true/false)", Retention_period]
#         ["AppServiceHTTPLogs", true, false, 0],
#         ["AppServiceConsoleLogs", true, false, 0],
#         ["AppServiceAppLogs", true, false, 0],
#         ["AppServiceAuditLogs", true, false, 0],
#         ["AppServiceIPSecAuditLogs", true, false, 0],
#         ["AppServicePlatformLogs", true, false, 0],
#       ]
#       metric = [
#         #["Category name",  "Diagnostics Enabled(true/false)", "Retention Enabled(true/false)", Retention_period]
#         ["AllMetrics", true, false, 0],
#       ]
#     }
#   }

# }

# # diagnostic_event_hub_namespaces = {
# #   event_hub_namespace1 = {
# #     name               = "security_operation_logs"
# #     resource_group_key = "webapp_rg_re1"
# #     sku                = "Standard"
# #     region             = "region1"
# #   }
# # }

# # # gcc is using govtech law, this is for non gcc
# # # resource id: /subscriptions/e22a351f-db36-4a02-9793-0f2189d5f3ab/resourceGroups/esdso-rg-ops-re1/providers/Microsoft.OperationalInsights/workspaces/esdso-log-agency-law
# diagnostic_log_analytics = {
#   central_logs_region1 = {
#     region             = "region1"
#     name               = "agency-law" # law resource name: esdso-log-agency-law
#     resource_group_key = "webapp_rg_re1"
#   }
# }

# diagnostics_destinations = {
#   # Storage keys must reference the azure region name
#   log_analytics = {   # <- this is destination type
#     central_logs = {  # <- this is destination key
#       # log_analytics_key              = "central_logs_region1"
#       # lz_key = "shared_services" # test remote key
#       # TODO: update the log_analytics_resource_id if using random code for name
#       log_analytics_resource_id = "/subscriptions/{{subscription_id}}/resourceGroups/{{prefix}}-rg-ops-re1/providers/Microsoft.OperationalInsights/workspaces/{{prefix}}-log-agency-law"
#       log_analytics_destination_type = "Dedicated"
#     }
#   }
#   # event_hub_namespaces = {
#   #   central_logs_example = {
#   #     event_hub_namespace_key = "event_hub_namespace1"
#   #   }
#   # }

#   # sample  # Storage keys must reference the azure region name
#   # log_analytics = {  # <- this is destination type
#   #   central_logs = { # <- this is destination key
#   #     # TODO: change to your subscription id
#   #     log_analytics_resource_id = "/subscriptions/{{subscription_id}}/resourceGroups/{{log_analytics_workspace_resource_group_name}}/providers/Microsoft.OperationalInsights/workspaces/{{log_analytics_workspace_name}}",
#   #     log_analytics_destination_type = "Dedicated"
#   #   }
#   # }

# }
