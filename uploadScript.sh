# Script takes a file, client key and api secret. It will ZIP the file and upload it to the batch API
#!/bin/bash
​
if [ $# -ne 3 ]
  then
    echo "3 input arguments expected"
    exit 1
fi
​
FILENAME=$1
CLIENTKEY=$2
APITOKEN=$3
​
ENDPOINT="https://api.boxever.com/v2/batches"
​
# Step 1: request for pre-signed URL
gzip -k $FILENAME
MD5=$(md5 $FILENAME.gz)
MD5=${MD5#"MD5 ($FILENAME.gz) = "}
echo "MD5 = "$MD5
UUID=$(uuidgen)
​
SIZE=$(wc -c $FILENAME.gz)
SIZE=${SIZE%$FILENAME.gz}
echo "SIZE = "$SIZE
​
AUTH=$(echo -n $CLIENTKEY:$APITOKEN | base64)
​
REQ="{\"checksum\":\"$MD5\", \"size\":$SIZE}"
echo "Request ref(UUID):" $UUID
echo "Request content:" $REQ
​
curl -v -X PUT -H "Authorization: Basic $AUTH" -H "Accept: application/json" -H "Content-Type: application/json" "$ENDPOINT/$UUID" -d "$REQ" > request_upload_url_response.json
​
# Step 2: upload file
B64MD5=$(echo -n $MD5 | xxd -r -p | base64)
echo "B64MD5 = "$B64MD5
​
UPLOADURL=$(cat request_upload_url_response.json | jq '.location.href')
UPLOADURL=${UPLOADURL#\"}
UPLOADURL=${UPLOADURL%\"}
​
​
echo "Upload URL:" $UPLOADURL
curl -H "x-amz-server-side-encryption: AES256" -H "Content-Md5: $B64MD5" -XPUT -T $FILENAME.gz "$UPLOADURL"
​
echo curl -X GET -H \"Authorization: Basic $AUTH\" -H \"Accept: application/json\" \"$ENDPOINT/$UUID\" > check_status_command.sh
# Step 3: output a script to be used to check status