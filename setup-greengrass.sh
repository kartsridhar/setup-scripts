GREENGRASS_VERSION=2.12.2
curl -s https://d2s8p88vqu9w66.cloudfront.net/releases/greengrass-${GREENGRASS_VERSION}.zip > greengrass-${GREENGRASS_VERSION}.zip
unzip greengrass-${GREENGRASS_VERSION}.zip -d GreengrassInstaller && rm greengrass-${GREENGRASS_VERSION}.zip

cat <<EOF >> initial-config.yaml
---
system:
  rootpath: "/greengrass/v2"
services:
  aws.greengrass.Nucleus:
    version: "${GREENGRASS_VERSION}"
    configuration:
      greengrassDataPlanePort: "443"
      mqtt:
        port: "443"
EOF

GGROOTDIR=/greengrass/v2
read -p "Enter the AWS region: " REGION
THINGNAME=$(hostname)
THINGGROUP="--thing-group-name ThingGroup"
THINGPOLICY=ThingPolicy
TOKENEXCHANGEROLE=GreenGrassTokenExchange
TOKENEXCHANGEROLEALIAS=GreenGrassCoreTokenExchangeAlias
sudo -E java -Droot="${GGROOTDIR}" -Dlog.store=FILE   -jar ~/GreengrassInstaller/lib/Greengrass.jar   --aws-region ${REGION}   --thing-name ${THINGNAME}   ${THINGGROUP}   --thing-policy-name ${THINGPOLICY}   --tes-role-name ${TOKENEXCHANGEROLE}   --tes-role-alias-name ${TOKENEXCHANGEROLEALIAS}   --component-default-user ggc_user:ggc_group   --provision true  --setup-system-service true --init-config initial-config.yaml
