#!/bin/bash
#This is a comment
case "$1" in 
start)
  /usr/local/bin/cpuhealth.sh &
  echo $!>/var/run/cpuhealth.pid
  ;;
stop)
  kill `cat /var/run/cpuhealth.pid`
  rm /var/run/cpuhealth.pid
  ;;
restart)
  $0 stop
  $0 start
  ;;
status)
  if [ -e /var/run/cpuhealth.pid ]; then
     echo cpuhealth.sh is running, pid=`cat /var/run/cpuhealth.pid`
  else
     echo cpuhealth.sh is NOT running
     exit 1
  fi
  ;;
*)
  echo "Usage: $0 {start|stop|status|restart}"
esac

exit 0 
