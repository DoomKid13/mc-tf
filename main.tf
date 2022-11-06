resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = "TF_minecraft"
}

resource "azurerm_kubernetes_cluster" "cluster" {
  name                = "TF_minecraft"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "minecraft"

  default_node_pool {
    name       = "default"
    node_count = "1"
    vm_size    = "standard_d2s_v3"
  }

  identity {
    type = "SystemAssigned"
  }

  http_application_routing_enabled = true
}

resource "azurerm_kubernetes_cluster_node_pool" "mem" {
  kubernetes_cluster_id = azurerm_kubernetes_cluster.cluster.id
  name                  = "mem"
  node_count            = "1"
  vm_size               = "standard_ds11_v2"
}

resource "kubernetes_config_map" "minecraft-bedrock-cm" {
  metadata {
    name = "minecraft-bedrock"
    labels = {
      "role" = "service-config"
      "app"  = "bds"
    }
  }

  data = {
    # Find more options at https://github.com/itzg/docker-minecraft-bedrock-server#server-properties
    # Remove # from in front of line if changing from default values.
    EULA : "TRUE" # Must accept EULA to use this minecraft server
    #GAMEMODE: "survival" # Options: survival, creative, adventure
    #DIFFICULTY: "easy" # Options: peaceful, easy, normal, hard
    #DEFAULT_PLAYER_PERMISSION_LEVEL: "member" # Options: visitor, member, operator
    #LEVEL_NAME: "my_minecraft_world"
    #LEVEL_SEED: "33480944"
    #SERVER_NAME: "my_minecraft_server"
    #SERVER_PORT: "19132"
    #LEVEL_TYPE: "DEFAULT" # Options: FLAT, LEGACY, DEFAULT
    #ALLOW_CHEATS: "false" # Options: true, false
    #MAX_PLAYERS: "10"
    #PLAYER_IDLE_TIMEOUT: "30"
    #TEXTUREPACK_REQUIRED: "false" # Options: true, false
    #
    ## Changing these will have a security impact
    #ONLINE_MODE: "true" # Options: true, false (removes Xbox Live account requirements)
    #WHITE_LIST: "false" # If enabled, need to provide a whitelist.json by your own means. 
    #
    ## Changing these will have a performance impact
    #VIEW_DISTANCE: "10"
    #TICK_DISTANCE: "4"
    #MAX_THREADS: "8"
    #
    ## Player Info
    OPS : "2535408967345176"
    WHITE_LIST_USERS : "Doom Kid 15"
    ENABLE-LAN-VISIBILITY : "true"
  }
}

resource "kubernetes_persistent_volume_claim" "minecraft-bedrock-pvc" {
  metadata {
    name = bds
  }

  spec {
    accessModes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }
}

resource "kubernetes_stateful_set" "minecraft-bedrock-ss" {
  metadata {
    name = "bds"
    labels = {
      "app" = "bds"
    }
  }

  spec {
    # never more than 1 since BDS is not horizontally scalable
    replicas     = 1
    service_name = bds
    selector {
      match_labels = {
        k8s-app = "bds"
      }
    }
    template {
      metadata {
        labels = {
          k8s-app = "bds"
        }
      }
      spec {
        
      }
    }
    volume_claim_template {
      metadata {
        name = "data"
      }

      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = "standard"

        resources {
          requests = {
            storage = "1Gi"
          }
        }
      }
    }
  }
}


