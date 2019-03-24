#!/usr/bin/env python3
import sys,datetime,subprocess,argparse,ipaddress,boto3

def getInfo(zoneName, fqdn, r53Client):
    if zoneName[-1] != '.':
        zoneName = zoneName + '.'

    for zone in r53Client.list_hosted_zones()['HostedZones']:
        if zone['Name'] == zoneName:
            zoneId = zone['Id']
            break

    lastIp = r53Client.list_resource_record_sets(
          HostedZoneId=zoneId,
          StartRecordName=fqdn)['ResourceRecordSets'][0]['ResourceRecords'][0]['Value'].strip()

    return lastIp, zoneId

def recordChangeParams(fqdn, newIp, dateTime):
    return {
            "Comment": "Updating in %s" % dateTime,
            "Changes": [
              {
                "Action": "UPSERT",
                "ResourceRecordSet": {
                  "Name": "%s" % fqdn,
                  "Type": "A",
                  "TTL": 300,
                  "ResourceRecords": [
                    {
                      "Value": "%s" % newIp
                    }
                  ]
                }
              }
            ]
          }

def validateIp(newIp):
    try:
        ip = ipaddress.ip_address(newIp)
        return True
    except ValueError:
        return False

def setRecordSet(r53Client, fqdn, newIp, dateTime, zoneId, recChangeParams):
    return r53Client.change_resource_record_sets(HostedZoneId=zoneId,ChangeBatch=recChangeParams)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
            description="Update Public IP to Route53",
            usage='''dynamicdns.py --zone <zone-name> --fqdn <FQDN> --pbip <public-ip>''')
    parser.add_argument('--zone', '-z', help="Zone Name (i.e. example.com)")
    parser.add_argument('--fqdn', '-f', help="Fully Qualified Domain Name (i.e. home.example.com)")
    parser.add_argument('--pbip', '-i', help="Public ip")
    args = parser.parse_args()

    dateTime = datetime.datetime.now()

    currentIp = args.pbip

    if not validateIp(currentIp):
        print ("Invalid IP address %s @ %s" % (currentIp, dateTime))
        sys.exit(1)

    r53Client = boto3.Session(profile_name='default').client('route53')

    lastIp,zoneId = getInfo(args.zone, args.fqdn, r53Client)

    recChangeParams = recordChangeParams(args.fqdn, currentIp, dateTime)

    if currentIp != lastIp:
        setRecordSet(r53Client, args.fqdn, currentIp, dateTime, zoneId, recChangeParams)
        print ("Updating %s : Ip's are different. Updating from %s to %s @ %s" % (args.fqdn, lastIp, currentIp, dateTime))
    else:
        print ("Updating %s : Same IP %s @ %s" % (args.fqdn, currentIp, dateTime))
