#!/bin/sh +e
# catch signals as PID 1 in a container

# SIGNAL-handler
term_handler() {  
  killall nginx
  exit 143; # 128 + 15 -- SIGTERM
}

FFMPEG_SETTINGS=""
HLS_SETTINGS=""

if ([ ENABLE_720P_2628KBS == "TRUE" ])
then
  FFMPEG_SETTINGS="$FFMPEG_SETTINGS -c:a libfdk_aac -b:a 128k -c:v libx264 -b:v 2500k -f flv -sc_threshold 0 -hls_time 4 -g 30 -r 30 -s 1280x720 -tune zerolatency -preset superfast -profile:v baseline rtmp://localhost:1935/hls/\$name_720p2628kbs"
  HLS_SETTINGS="$HLS_SETTINGS\n    hls_variant _720p2628kbs BANDWIDTH=2628000,RESOLUTION=1280x720;"
fi

if ([ ENABLE_480P_1128KBS == "TRUE" ])
then
  FFMPEG_SETTINGS="$FFMPEG_SETTINGS -c:a libfdk_aac -b:a 128k -c:v libx264 -b:v 1000k -f flv -sc_threshold 0 -hls_time 4 -g 30 -r 30 -s 854x480 -tune zerolatency -preset superfast -profile:v baseline rtmp://localhost:1935/hls/\$name_480p1128kbs"
  HLS_SETTINGS="$HLS_SETTINGS\n    hls_variant _480p1128kbs BANDWIDTH=1128000,RESOLUTION=854x480;"
fi

if ([ ENABLE_360P_878KBS == "TRUE" ])
then
  FFMPEG_SETTINGS="$FFMPEG_SETTINGS -c:a libfdk_aac -b:a 128k -c:v libx264 -b:v 750k -f flv -sc_threshold 0 -hls_time 4 -g 30 -r 30 -s 640x360 -tune zerolatency -preset superfast -profile:v baseline rtmp://localhost:1935/hls/\$name_360p878kbs"
  HLS_SETTINGS="$HLS_SETTINGS\n    hls_variant _360p878kbs BANDWIDTH=878000,RESOLUTION=640x360;"
fi

if ([ ENABLE_240P_528KBS == "TRUE" ])
then
  FFMPEG_SETTINGS="$FFMPEG_SETTINGS -c:a libfdk_aac -b:a 128k -c:v libx264 -b:v 400k -f flv -sc_threshold 0 -hls_time 4 -g 30 -r 30 -s 426x240 -tune zerolatency -preset superfast -profile:v baseline rtmp://localhost:1935/hls/\$name_240p528kbs"
  HLS_SETTINGS="$HLS_SETTINGS\n    hls_variant _240p528kbs BANDWIDTH=528000,RESOLUTION=426x240;"
fi

if ([ ENABLE_240P_264KBS == "TRUE" ])
then
  FFMPEG_SETTINGS="$FFMPEG_SETTINGS -c:a libfdk_aac -b:a 64k -c:v libx264 -b:v 200k -f flv -sc_threshold 0 -hls_time 4 -g 15 -r 15 -s 426x240 -tune zerolatency -preset superfast -profile:v baseline rtmp://localhost:1935/hls/\$name_240p264kbs"
  HLS_SETTINGS="$HLS_SETTINGS\n    hls_variant _240p264kbs BANDWIDTH=264000,RESOLUTION=426x240;"
fi

export FFMPEG_SETTINGS=$FFMPEG_SETTINGS
export HLS_SETTINGS=$HLS_SETTINGS

# on callback, stop all started processes in term_handler
trap 'kill ${!}; term_handler' SIGINT SIGKILL SIGTERM SIGQUIT SIGTSTP SIGSTOP SIGHUP
if ([ "${USE_SSL}" == "" ])
then
  USE_SSL="#"
fi
if ([ "${DOMAIN_NAME}" != "" ]) 
then 
  USE_SSL=""
fi

export USE_SSL=$USE_SSL

if ([ -f /etc/letsencrypt/live/${DOMAIN_NAME}/privkey.pem ])
then
  echo SSL OK...
else
  echo SSL not OK...
  export USE_SSL="#"
fi

#updating variables in nginx.conf
envsubst "$(env | sed -e 's/=.*//' -e 's/^/\$/g')" < \
  /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf 
  
nginx &

if ([ "${DOMAIN_NAME}" != "" ]) 
then 
  sleep 10
  if ([ -f /etc/letsencrypt/live/${DOMAIN_NAME}/privkey.pem ])
  then
    certbot renew
  else
    certbot run -a nginx -i nginx --rsa-key-size 4096 --agree-tos --no-eff-email --email example@email.com  -d ${DOMAIN_NAME}
    killall nginx
    export USE_SSL=$USE_SSL
    #updating variables in nginx.conf
    envsubst "$(env | sed -e 's/=.*//' -e 's/^/\$/g')" < \
      /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf 
    nginx &
  fi
fi



# wait forever not to exit the container
while true
do
  tail -f /dev/null & wait ${!}
done

exit 0
