function dock-ci
    docker rmi -f (docker images | grep "^<none>" | awk "{print \$3}")
end
