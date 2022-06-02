@description('Name of the Log Analytics workspace used by Microsoft Sentinel.')
param logAnalyticsWorkspaceName string

// Reference the existing Log Analytics workspace
resource workspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
    name: logAnalyticsWorkspaceName
}

// Deploy the codeless data connector to the Log Analytics workspace
resource codelessConnector 'Microsoft.SecurityInsights/dataConnectors@2021-09-01-preview' = {
    scope: workspace
    name: guid(resourceGroup().id, 'Cloudability test connector')
    kind: 'APIPolling'
    properties: {
      connectorUiConfig: {
        title: 'Cloudability connector test'
        publisher: 'Finastra - Architecture and Practice Team'
        descriptionMarkdown: 'Test the connector for Microsoft Sentinel'
        availability: {
            isPreview: true
            status: '1'
        }
        graphQueriesTableName: 'Cloudability_ACC_CL'
        graphQueries: [
            {
                baseQuery: '{{graphQueriesTableName}}'
                legend: 'Cloubability Accounts records'
                metricName: 'Total data recieved'
            }
        ]
        dataTypes: [
            {
                lastDataReceivedQuery: '{{graphQueriesTableName}}\n| summarize Time = max(TimeGenerated)\n| where isnotempty(Time)'
                name: '{{graphQueriesTableName}}'
            }
        ]
        connectivityCriteria: [
            {
                type: 'SentinelKindsV2'
            }
        ]
        permissions: {
            resourceProvider: [
                {
                    permissionsDisplayText: 'Read and Write permissions on the Log Analytics workspace are required to enable the data connector'
                    provider: 'Microsoft.OperationalInsights/workspaces'
                    providerDisplayName: 'Workspace'
                    requiredPermissions: {
                        delete: true
                        read: true
                        write: true
                    }
                    scope: 'Workspace'
                }
            ]
            customs: [
                {
                    description: 'An Cloudability API token is required to ingest audit records to Microsoft Sentinel.'
                    name: 'Cloudability API token'
                }
            ]
        }
        instructionSteps: [
            {
                title: 'Connect the Cloudability REST API with Microsoft Sentinel'
                description: 'Enter your Cloudability domain, username and API token.'
                instructions: [
                    {
                        parameters: {
                            enable: true
                            userRequestPlaceHoldersInput: [
                                {
                                    displayText: 'Domain name'
                                    requestObjectKey: 'apiEndpoint'
                                    placeHolderName: '{{domain}}'
                                    placeHolderValue: ''
                                }
                            ]
                        }
                        type: 'BasicAuth'
                    }
                ]
            }
        ]
        sampleQueries: [
            {
                description: 'List all Cloudability Account records'
                query: '{{graphQueriesTableName}}\n| sort by TimeGenerated desc'
            }
        ]
    }
    pollingConfig: {
      auth: {
          authType: 'Basic'
      }
      request: {
          apiEndpoint: 'https://{{domain}}/v3/vendors'
          headers: {
              'accept': 'application/json'
          }
          httpMethod: 'Get'
      }
      paging: {
          pagingType: 'Offset'
          offsetParaName: 'offset'
          pageSizeParaName: 'limit'
          pageSize: 1000
      }
      response: {
          eventsJsonPaths: [
              '$..result'
          ]
      }
  }
    }
}
