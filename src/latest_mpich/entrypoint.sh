#!/bin/bash
set -e
IP_ADDRESS=$(hostname --ip-address)
USER_ID=${LOCAL_USER_ID:-9001}

if [[ ! $(id -u nest) = $USER_ID ]]; then
	echo "UID : $USER_ID"
	adduser --disabled-login --gecos 'NEST' --uid $USER_ID --home /home/nest nest
	export HOME=/home/nest
fi

echo '. /opt/nest/bin/nest_vars.sh' >> /home/nest/.bashrc

# NEST environment
source /opt/nest/bin/nest_vars.sh

# Running NEST to test and to copy the .nestrc into /home/nest
nest --help
chown nest:nest /home/nest/.nestrc

export MUSIC_ROOT_DIR=/opt/music-install
export MUSIC_ROOT=${MUSIC_ROOT_DIR}
MUSIC_PATH=${MUSIC_ROOT_DIR}
export LD_LIBRARY_PATH=${MUSIC_PATH}/lib:$LD_LIBRARY_PATH
export PATH=${MUSIC_PATH}/bin:$PATH
export CPATH=${MUSIC_PATH}/include:$CPATH
export PYTHONPATH=${MUSIC_PATH}/lib/python3.8/site-packages:$PYTHONPATH

if [[ ! -d /opt/data ]]; then
	mkdir /opt/data
	chown -R nest:nest /opt/data
fi

if [[ "$1" = 'notebook' ]]; then
    cd /opt/data
    exec gosu nest jupyter-notebook --ip="${IP_ADDRESS}" --port=8080 --no-browser
fi

if [[ "$1" = 'nest-server' ]]; then
    cd /opt/data
    NEST_SERVER_RESTRICTION_OFF=TRUE
    exec gosu nest nest-server start -o -h 0.0.0.0 -p 5000 -u $UID
fi

if [[ "$1" = 'interactive' ]]; then
    read -p "Your python script: " name
	echo Starting: $name
	cd /opt/data
	# Start
	exec gosu nest python3 /opt/data/$name
fi

cd /opt/data
exec gosu nest "$@"
