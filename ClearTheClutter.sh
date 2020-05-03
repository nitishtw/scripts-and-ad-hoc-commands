#!/bin/bash
cd ~/Pictures/
mapfile -t my_array < <( stat -c "%y" *.* |  cut -d ' ' -f '1' | sort -u  | sort -n )
printf '%s\n' ${my_array[*]}
for each in "${my_array[@]}"
do
    mkdir -p ~/Pictures/$each
    for  i in "${10#each[@]}"
    do
        find ~/Pictures/ -type f -newermt "${each[i]}" ! -newermt "${each[i+1]}" -exec mv -t ~/Pictures/$each {} +
    done
done
