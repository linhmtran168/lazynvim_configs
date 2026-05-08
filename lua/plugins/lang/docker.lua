-- Docker: dockerls covers Dockerfile; docker-compose-language-service handles
-- compose YAML (registers as the LSP for filetype `yaml.docker-compose`).
return {
  servers = {
    dockerls = {},
    docker_compose_language_service = {},
  },
  parsers = { "dockerfile" },
  mason_tools = { "dockerfile-language-server", "docker-compose-language-service" },
}
