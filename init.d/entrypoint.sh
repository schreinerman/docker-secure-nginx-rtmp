#!/bin/sh +e
# catch signals as PID 1 in a container

# SIGNAL-handler
term_handler() {  
  killall nginx
  exit 143; # 128 + 15 -- SIGTERM
}

FFMPEG_SETTINGS=""
HLS_SETTINGS=""
LN="
"
SPACE="            "
USE_SERVER_NAME=""

if ([ $ENABLE_720P_2628KBS == "TRUE" ])
then
  FFMPEG_SETTINGS="$FFMPEG_SETTINGS\\${LN}${SPACE} -c:a libfdk_aac -b:a 128k -c:v libx264 -b:v 2500k -f flv -sc_threshold 0 -hls_time 4 -g 30 -r 30 -s 1280x720 -tune zerolatency -preset superfast -profile:v baseline rtmp://localhost:1935/hls/\$name_720p2628kbs"
  HLS_SETTINGS="${HLS_SETTINGS}${LN}${SPACE}hls_variant _720p2628kbs BANDWIDTH=2628000,RESOLUTION=1280x720;"
fi

if ([ $ENABLE_480P_1128KBS == "TRUE" ])
then
  FFMPEG_SETTINGS="$FFMPEG_SETTINGS\\${LN}${SPACE} -c:a libfdk_aac -b:a 128k -c:v libx264 -b:v 1000k -f flv -sc_threshold 0 -hls_time 4 -g 30 -r 30 -s 854x480 -tune zerolatency -preset superfast -profile:v baseline rtmp://localhost:1935/hls/\$name_480p1128kbs"
  HLS_SETTINGS="${HLS_SETTINGS}${LN}${SPACE}hls_variant _480p1128kbs BANDWIDTH=1128000,RESOLUTION=854x480;"
fi

if ([ $ENABLE_360P_878KBS == "TRUE" ])
then
  FFMPEG_SETTINGS="$FFMPEG_SETTINGS\\${LN}${SPACE} -c:a libfdk_aac -b:a 128k -c:v libx264 -b:v 750k -f flv -sc_threshold 0 -hls_time 4 -g 30 -r 30 -s 640x360 -tune zerolatency -preset superfast -profile:v baseline rtmp://localhost:1935/hls/\$name_360p878kbs"
  HLS_SETTINGS="${HLS_SETTINGS}${LN}${SPACE}hls_variant _360p878kbs BANDWIDTH=878000,RESOLUTION=640x360;"
fi

if ([ $ENABLE_240P_528KBS == "TRUE" ])
then
  FFMPEG_SETTINGS="$FFMPEG_SETTINGS\\${LN}${SPACE} -c:a libfdk_aac -b:a 128k -c:v libx264 -b:v 400k -f flv -sc_threshold 0 -hls_time 4 -g 30 -r 30 -s 426x240 -tune zerolatency -preset superfast -profile:v baseline rtmp://localhost:1935/hls/\$name_240p528kbs"
  HLS_SETTINGS="${HLS_SETTINGS}${LN}${SPACE}hls_variant _240p528kbs BANDWIDTH=528000,RESOLUTION=426x240;"
fi

if ([ $ENABLE_240P_264KBS == "TRUE" ])
then
  FFMPEG_SETTINGS="$FFMPEG_SETTINGS\\${LN}${SPACE} -c:a libfdk_aac -b:a 64k -c:v libx264 -b:v 200k -f flv -sc_threshold 0 -hls_time 4 -g 15 -r 15 -s 426x240 -tune zerolatency -preset superfast -profile:v baseline rtmp://localhost:1935/hls/\$name_240p264kbs"
  HLS_SETTINGS="${HLS_SETTINGS}${LN}${SPACE}hls_variant _240p264kbs BANDWIDTH=264000,RESOLUTION=426x240;"
fi

export FFMPEG_SETTINGS=$FFMPEG_SETTINGS
export HLS_SETTINGS=$HLS_SETTINGS

# on callback, stop all started processes in term_handler
trap 'kill ${!}; term_handler' SIGINT SIGKILL SIGTERM SIGQUIT SIGTSTP SIGSTOP SIGHUP


FILE_CERT_PRIVATE=""
FILE_CERT_PUBLIC=""
USE_LETS_ENCRYPT=y
USE_SSL="#"

if ([ "${EMAIL}" == "" ])
then
  EMAIL="example@email.com"
fi

#validating SSL private certificate
if ([ "${CERT_PRIVATE_KEY}" != "" ])
then
   if ([ -f "${CERT_PRIVATE_KEY}" ])
   then
      FILE_CERT_PRIVATE=${CERT_PRIVATE_KEY}
   fi
   if ([ -f "/opt/certs/${CERT_PRIVATE_KEY}" ])
   then
      FILE_CERT_PRIVATE="/opt/certs/${CERT_PRIVATE_KEY}"
   fi
fi

#validating SSL public certificate
if ([ "${CERT_PUBLIC}" != "" ])
then
   if ([ -f "${CERT_PUBLIC}" ])
   then
      FILE_CERT_PUBLIC=${CERT_PUBLIC}
   fi
   if ([ -f "/opt/certs/${CERT_PUBLIC}" ])
   then
      FILE_CERT_PUBLIC="/opt/certs/${CERT_PUBLIC}"
   fi
fi

#validating SSL certificates
if ([ -f "${FILE_CERT_PRIVATE}" ])
then
  echo Private SSL Key found...
  if ([ -f "${FILE_CERT_PUBLIC}" ])
  then
     echo Public SSL Key found...
     USE_LETS_ENCRYPT=n
     USE_SSL=""
  fi
fi

if ([ ${USE_LETS_ENCRYPT} == "y" ])
then
  if ([ "${DOMAIN_NAME}" != "" ]) 
  then 
    echo Using Letsencrypt...
    FILE_CERT_PUBLIC="/etc/letsencrypt/live/${DOMAIN_NAME}/fullchain.pem"
    FILE_CERT_PRIVATE="/etc/letsencrypt/live/${DOMAIN_NAME}/privkey.pem"
    USE_SSL=""
  else
    echo Not using Letsencrypt...
    USE_SSL="#"
    USE_LETS_ENCRYPT=n
  fi
fi

if ([ "${DOMAIN_NAME}" != "" ]) 
then
    USE_SERVER_NAME="server_name ${DOMAIN_NAME};"
fi

if ([ "${USE_SSL}" == "" ])
then
  echo SSL disabled...
fi

export USE_SSL=$USE_SSL

if ([ ${USE_LETS_ENCRYPT} == "y" ])
then
  if ([ -f ${FILE_CERT_PRIVATE} ])
  then
    echo Letsencrypt SSL OK...
  else
    echo SSL Letsencrypt is not OK...
    echo Disabling SSL for now...
    export USE_SSL="#"
  fi
fi

export FILE_CERT_PUBLIC=$FILE_CERT_PUBLIC
export FILE_CERT_PRIVATE=$FILE_CERT_PRIVATE
export USE_SERVER_NAME=""   
#updating variables in nginx.conf
echo Updating NGINX Config...
envsubst "$(env | sed -e 's/=.*//' -e 's/^/\$/g')" < \
  /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf 
  
echo Stopping NGINX...
killall -9 nginx
nginx &

if ([ ${USE_LETS_ENCRYPT} == "y" ])
then 
  export USE_SERVER_NAME=$USE_SERVER_NAME
  killall nginx
  sleep 5
  killall -9 nginx
  nginx &
  #updating variables in nginx.conf
  echo Updating NGINX Config...
  envsubst "$(env | sed -e 's/=.*//' -e 's/^/\$/g')" < \
  /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf 
  sleep 5
  if ([ -f ${FILE_CERT_PRIVATE} ])
  then
    echo Check for renewal Letsencrypt required...
    certbot renew
  else
    echo Initial Letsencrypt actions are required...
    certbot run -a nginx -i nginx --rsa-key-size 4096 --agree-tos --force-renewal -n --no-eff-email --email ${EMAIL}  -d ${DOMAIN_NAME}

    echo Stopping NGINX...
    killall nginx
    sleep 5

    echo Enabling SSL...
    export USE_SSL=$USE_SSL
  fi
  export USE_SERVER_NAME=""
  #updating variables in nginx.conf
  echo Updating NGINX Config...
  envsubst "$(env | sed -e 's/=.*//' -e 's/^/\$/g')" < \
    /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf 

  echo Starting NGINX...
  killall -9 nginx
  nginx &
fi



# wait forever not to exit the container
while true
do
  tail -f /dev/null & wait ${!}
done

exit 0
