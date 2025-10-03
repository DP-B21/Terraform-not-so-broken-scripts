#!/bin/sh

#F_SIZE=$(ll /var.lib.rundeck/scripts -S | awk 'NR==2 {print $5}')
FILE=$(ls -lt /root/rundeck-containers/ | awk 'NR==2 {print $9}')

#echo $FILE >> test.txt


if [ -f "test.txt" ]; then
:
else
echo "test.txt doesn't exist"
echo "creating test.txt"
touch /var/lib/rundeck/scripts/test.txt
TEST=/var/lib/rundeck/scripts/test.txt
fi

LINES=$(cat /root/rundeck-containers/$FILE | wc -l)
ALL_LINES=$(cat /var/lib/rundeck/scripts/test.txt | wc -l)
let "SUB=$ALL_LINES-$LINES"

if grep $FILE test.txt ;
then
echo "works"
sed -i -e "${SUB}",'$d' test.txt
else
echo "$FILE not found."
echo "preparing $FILE"
cat /root/rundeck-containers/$FILE >> /var/lib/rundeck/scripts/test.txt
fi


#FILE=$(/root/rundeck-containers/$FILE)
#echo $FILE


#echo $LINES
#echo $ALL_LINES
#echo $SUB
#to delete the line
