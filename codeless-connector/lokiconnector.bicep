@description('Name of the Log Analytics workspace used by Microsoft Sentinel.')
param logAnalyticsWorkspaceName string

// Reference the existing Log Analytics workspace
resource workspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
    name: logAnalyticsWorkspaceName
}

// Deploy the codeless data connector to the Log Analytics workspace
resource codelessConnector 'Microsoft.SecurityInsights/dataConnectors@2021-09-01-preview' = {
    scope: workspace
    name: guid(resourceGroup().id, 'Loki instance connector')
    kind: 'APIPolling'
    properties: {
      connectorUiConfig: {
        title: 'Loki Connector '
        publisher: 'Finastra - Architecture and Practice Team'
        descriptionMarkdown: 'Test the connector for Microsoft Sentinel'
        availability: {
            isPreview: true
            status: '1'
        }
        graphQueriesTableName: 'LokiLogs_CL'
        graphQueries: [
            {
                baseQuery: '{{graphQueriesTableName}}'
                legend: 'Loki Logs records'
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
                    description: 'An Loki instance API token is required to ingest logs records to Microsoft Sentinel.'
                    name: 'Loki instance API token'
                }
            ]
        }
        instructionSteps: [
            {
                title: 'Connect the Loki REST API with Microsoft Sentinel'
                description: 'Enter your Loki domain and API Key.'
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
                        type: 'APIKey'
                    }
                ]
            }
        ]
        sampleQueries: [
            {
                description: 'List all Loki Logs records'
                query: '{{graphQueriesTableName}}\n| sort by TimeGenerated desc'
            }
        ]
    }
    pollingConfig: {
      auth: {
          authType: 'APIKey'
          APIKeyIdentifier: 'Bearer'
          APIKeyName: 'Authorization'
      }
      request: {
          apiEndpoint: 'https://{{domain}}/loki/api/v1/query_range?query=%7Bvm=%22F5%22%7D'
          headers: {
              'accept': 'application/json'
          }
          httpMethod: 'Get'
      }
      paging: {
          pagingType: 'NextPageToken'
          nextPageParaName: 'next'
          nextPageTokenJsonPath: '$.next'
      }
      response: {
          eventsJsonPaths: [
              '$.data.result'
          ]
      }
  }
    }
}
