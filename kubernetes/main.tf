resource "local_file" "kubeconfig" {
  content  = var.kubeconfig
  filename = "${path.root}/kubeconfig"
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
    name = "bds"
  }

  spec {
    access_modes = ["ReadWriteOnce"]
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
    service_name = "bds"
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
        container {
          name              = "main"
          image             = "doomkid13/minecraft-bedrock-server"
          image_pull_policy = "Always"
          env_from {
            config_map_ref {
              name = kubernetes_config_map.minecraft-bedrock-cm.metadata[0].name
            }
          }

          volume_mount {
            mount_path = "/data"
            name       = "data"
          }

          port {
            container_port = 19132
            protocol       = "UDP"
          }

          readiness_probe {
            exec {
              # force health check against IPv4 port
              command = ["mc-monitor", "status-bedrock", "--host", "127.0.0.1"]
            }
            initial_delay_seconds = 30
          }
          
          liveness_probe {
            exec {
              # force health check against IPv4 port
              command = ["mc-monitor", "status-bedrock", "--host", "127.0.0.1"]
            }
            initial_delay_seconds = 30
          }
          tty = true
          stdin = true
        }
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

resource "kubernetes_service" "minecraft-bedrock-svc" {
  metadata {
    name = "bds"
  }

  spec {
    type = "LoadBalancer"

    selector = {
      "app" = "bds"
    }

    port {
      port = 19132
      target_port = 19132
      protocol = "UDP"
      name = "bds-udp"
    }

    ip_families = [ "IPv4" ]
  }
}


