#!/bin/bash

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -z|--zone)
    ZONE="$2"
    shift # past argument
    shift # past value
    ;;
    -f|--fqdn)
    FQDN="$2"
    shift # past argument
    shift # past value
    ;;
    -i|--pbip)
    PBIP="$2"
    shift # past argument
    shift # past value
    ;;
esac
done

# Get current dir
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Get aws credentials based on profile
# Thumbs up for @whereisaaron on github (https://github.com/whereisaaron/get-aws-profile-bash)
AWS_ACCESS_KEY_ID=$($DIR/get-aws-profile.sh --profile default --key)
AWS_SECRET_ACCESS_KEY=$($DIR/get-aws-profile.sh --profile default --secret)

# Get the external IP input
ACTUALIP=$(echo $PBIP)

# Get hosted zone id from zone name
ZONEID=$(aws route53 list-hosted-zones --query "HostedZones[?Name == '$ZONE.'].Id" --output=text | awk -F "/" '{print {$3}')

# Get the aws recorded IP address from Route53
RECORDIP=$(aws route53 list-resource-record-sets --hosted-zone-id $ZONEID --query "ResourceRecordSets[?Name == '$RECORDSET.'].ResourceRecords[0].Value" --output=text)

function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}


#Define files
LOGFILE=$DIR/update-route53.log

if ! valid_ip $ACTUALIP; then
    echo "Invalid IP address $ACTUALIP @ $(date)" >> $LOGFILE
    exit 1
fi

if [[ $ACTUALIP != $RECORDIP ]] ; then
    TMPFILE=$(mktemp)
    tee $TMPFILE <<EOF
{
  "Comment":"Updating @ $(date)",
  "Changes":[{
    "Action":"UPSERT",
    "ResourceRecordSet":{
      "ResourceRecords":[{
        "Value":"$ACTUALIP"
      }],
      "Name":"$FQDN.",
      "Type":"A",
      "TTL":300
    }
  }]
}
EOF

    # Update the Hosted Zone record
    aws route53 change-resource-record-sets --hosted-zone-id $ZONEID --change-batch file://$TMPFILE

    echo "Updating $FQDN : IP has changed from $RECORDIP to $ACTUALIP @ $(date)" >> $LOGFILE

    # Clean up
    rm $TMPFILE
else
    echo "Updating $FQDN : Same IP $ACTUALIP @ $(date)" >> $LOGFILE
    exit 0
fi
