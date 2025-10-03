#!/bin/sh

DIR="past_checks"
SUBNET="192.41.122"
DATE=$(date +%d-%m-%Y-%H-%M:%S)

#CHANGE THIS IF YOU WANT TO CHANGE THE LIMIT OF PREVIOUS VERSION FILES 
DEL_FILE_AMMOUNT=3


if [ -d "$DIR" ]; then
  echo "$DIR/ directory already exists. skipping..."
else
  echo "creating $DIR/ directory "
  mkdir -p "$DIR"
fi

VERSION_FILE="$DIR/"$DATE"_check"
VER_FILE_COUNT=$(ls "$DIR" | wc -l )



if [ $VER_FILE_COUNT -gt $((DEL_FILE_AMMOUNT - 1)) ]; then

	while [ $VER_FILE_COUNT -gt $((DEL_FILE_AMMOUNT - 1)) ]; do
		VER_FILE_NAME=$(ls "$DIR" -lt | awk 'END {print $NF}')
        	VER_FILE_DEL="$DIR/$VER_FILE_NAME"
		rm $VER_FILE_DEL
	
		VER_FILE_COUNT=$(ls "$DIR" | wc -l)	
	done
	fi


echo -e "\033[0;33mScanning this may take a while....\033[0m"

# Loop through all possible IP addresses in the /24 subnet
for i in $(seq 1 254); do
  IP="$SUBNET.$i"

  # Check SSH version and append IP with the result if found
  SSH_OUTPUT=$(ssh -o ConnectTimeout=1 -o ConnectionAttempts=1 -o BatchMode=yes -o StrictHostKeyChecking=no "$IP" -v 2>&1)
  if echo "$SSH_OUTPUT" | grep -q "Remote protocol version"; then
    echo "$IP: $(echo "$SSH_OUTPUT" | grep "Remote protocol version")" >> "$VERSION_FILE"
    echo -e "\e[1;32m$IP is connected\e[0m"
    
  else
   echo "$IP not connected" >> "$VERSION_FILE"

  fi
done



echo "Completed checking SSH versions. Check $VERSION_FILE for results."



