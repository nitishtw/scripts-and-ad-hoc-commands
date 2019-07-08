#!/bin/bash
exec &> /tmp/removenodeandclient.log
for id in $*
do
	knife node delete $id -y &
	knife client delete $id -y &
	echo $id
done
