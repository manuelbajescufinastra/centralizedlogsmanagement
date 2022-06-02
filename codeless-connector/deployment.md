# Deployment command
To deploy the .bicep file useh the command: 
'az deployment group create --resource-group clmrg  --template-file lokiconnector.bicep --parameters logAnalyticsWorkspaceName=clmworkspace'
