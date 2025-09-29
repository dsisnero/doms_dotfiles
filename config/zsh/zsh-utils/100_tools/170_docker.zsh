#!/usr/bin/env zsh

# Docker Compose utility function
# Smart wrapper that chooses between 'docker compose run' and 'docker compose exec'
# If the service is not running, it uses 'run --rm' to start a new container
# If the service is already running, it uses 'exec' to run commands in the existing container
dcrun () {
  service_name=$1
  shift

  # Check if the service container is currently running
  if [ -z "$(docker compose ps $service_name --format "{{ .Status }}" --filter "status=running")" ]; then
    # Service is not running - start a new container with 'run --rm' (automatically remove after execution)
    docker compose run --rm $service_name $@
  else
    # Service is already running - execute command in existing container with 'exec'
    docker compose exec $service_name $@
  fi
}
