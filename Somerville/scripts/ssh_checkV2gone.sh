#!/bin/sh

CURRENT_DATE=$(date +"%Y-%m-%d%H:%M:%S")
DIR="ssh_ver_check"
SUBNET="192.41.122"
TMP_FILE="/tmp/ssh_ver_check_temp.txt"
VERSION_FILE="./ip_list.txt"
SCANNED_DIR="scanned"
SCANNED_FILE="${SCANNED_DIR}/${CURRENT_DATE}_scan"

# Check if the directory exists, create if it does not
if [ -d "$DIR" ]; then
  echo "$DIR already exists. skipping..."
else
  echo "Creating $DIR and $SCANNED_DIR directories"
  mkdir -p "$DIR"
  mkdir -p "$SCANNED_DIR"
fi

# Temporary file check
if [ -f "$TMP_FILE" ]; then
  echo "$TMP_FILE already exists"
else
  echo "creating $TMP_FILE..."
  touch "$TMP_FILE"
fi

# Clear the VERSION_FILE if it already exists
if [ -f "$VERSION_FILE" ]; then
  > "$VERSION_FILE"
  echo "Cleared existing $VERSION_FILE"
else
  touch "$VERSION_FILE"
  echo "Creating $VERSION_FILE"
fi

# Loop through all possible IP addresses in the /24 subnet
for i in $(seq 1 254); do
  IP="$SUBNET.$i"

  # Check SSH version and append IP with the result if found
  SSH_OUTPUT=$(ssh -o ConnectTimeout=2 -o BatchMode=yes -o StrictHostKeyChecking=no "$IP" -v 2>&1)
  if echo "$SSH_OUTPUT" | grep -q "Remote protocol version"; then
    PASSED_VER="$IP: $(echo "$SSH_OUTPUT" | grep "Remote protocol version")"
    echo "$PASSED_VER" >> "$VERSION_FILE"
    echo "$PASSED_VER"
  else

    CHECK_FAIL="$IP not connected"
    echo "$CHECK_FAIL"
    echo "$CHECK_FAIL" >> "$VERSION_FILE"
  fi
done

# Remove "debug1:" from the output file
sed -i 's/debug1: //g' "$VERSION_FILE"

# Check and process scanned directory
if [ "$(ls -A "$SCANNED_DIR")" ]; then
  echo "Completed checking SSH versions. Check $VERSION_FILE for results."
else
  echo "Comparing SSH versions and newly found machines"
fi

# Save the current results as a scanned file
cat "$VERSION_FILE" > "$SCANNED_FILE"



# Remove the temporary file
rm "$TMP_FILE"

