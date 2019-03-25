job "nginx" {
  datacenters = ["dc1"]

  group "nginx" {
    count = 3
    task "server" {
      driver = "docker"
      resources {
        network {
          port "http" {}
        }
      }

      config {
        image = "nginx"
        port_map = {
          http = 80
        }
      }

      service {
        name = "nginx"
        port = "http"
        tags = ["traefik.enable=true"]
      }
    }
  }
}
