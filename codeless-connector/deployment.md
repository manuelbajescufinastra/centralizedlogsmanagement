# Deployment command
To deploy the .bicep file used the command: 
`az deployment group create --resource-group SendhilACM  --template-file lokiconnector.bicep --parameters logAnalyticsWorkspaceName=clmworkspace`
