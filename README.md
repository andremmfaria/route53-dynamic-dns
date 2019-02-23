# Route53 as a dynamic dns service
At first i only did these scripts in bash and python. But if you want, feel free to make a PR for any other language and/or correction
If there is the specific need for a correction raise an issue and, when i have the time, i'll correct it

## Usage
 
### Python
```shell
python3 dynamicdns.py --zone <zone-name> --fqdn <FQDN> --pbip <public-ip>
```

### Shell
```shell
sh dynamicdns.sh --zone <zone-name> --fqdn <FQDN> --pbip <public-ip>
```

## Recommendations 
I recommend using OpenDNS to discover your external ip
Command: 
```shell
sh dig +short myip.opendns.com @resolver1.opendns.com
```
With that the commands for the scripts are:
```shell
python3 dynamicdns.py --zone example.com --fqdn foo.example.com --pbip $(dig +short myip.opendns.com @resolver1.opendns.com)
sh dynamicdns.sh --zone example.com --fqdn bar.example.com --pbip $(dig +short myip.opendns.com @resolver1.opendns.com)
```

In the same manner i recommend that you create a cron job to refresh your ip public ip on route53 and log the results
```
*/10 * * * * ~/path-to-folder/python/dynamicdns.py --zone example.com --fqdn foo.example.com --pbip $(dig +short myip.opendns.com @resolver1.opendns.com) >> ~/path-to-folder/update-route53.log

*/10 * * * * ~/path-to-folder/shell/dynamicdns.sh --zone example.com --fqdn foo.example.com --pbip $(dig +short myip.opendns.com @resolver1.opendns.com) >> ~/path-to-folder/update-route53.log
```
The above example states that the script will run every 10 minutes

## Special thanks

Thumbs up for @whereisaaron on github (https://github.com/whereisaaron/get-aws-profile-bash) for the aws credentials parse script :D
