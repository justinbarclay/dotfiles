function dock-cc
    docker ps -q -a -f status=exited | xargs -n 100 docker rm -v
end
