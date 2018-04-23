function run-docker-osx
    export DOCKER_HOST="tcp://192.168.59.103:2376"
    export DOCKER_TLS_VERIFY=1
    export DOCKER_CERT_PATH="/Users/Justin/.boot2docker/certs/boot2docker-vm"

    docker-osx-dev
end
