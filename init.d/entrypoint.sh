#!/bin/sh +e
# catch signals as PID 1 in a container

# SIGNAL-handler
term_handler() {  
  killall nginx
  exit 143; # 128 + 15 -- SIGTERM
}

# on callback, stop all started processes in term_handler
trap 'kill ${!}; term_handler' SIGINT SIGKILL SIGTERM SIGQUIT SIGTSTP SIGSTOP SIGHUP
if ([ "${USE_SSL}" != "" ])
then
  USE_SSL="#"
fi
if ([ "${DOMAIN_NAME}" != "" ]) 
then 
  USE_SSL=""
fi

export USE_SSL=$USE_SSL

#updating variables in nginx.conf
envsubst "$(env | sed -e 's/=.*//' -e 's/^/\$/g')" < \
  /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf 
  
  
if ([ "${DOMAIN_NAME}" != "" ]) 
then 
  if [ -f /etc/letsencrypt/live/${DOMAIN_NAME}/privkey.pem ]
  then
    certbot renew
  else
    certbot run -a nginx -i nginx --rsa-key-size 4096 --agree-tos --no-eff-email --email example@email.com  -d ${DOMAIN_NAME}
  fi
fi

nginx &

# wait forever not to exit the container
while true
do
  tail -f /dev/null & wait ${!}
done

exit 0
