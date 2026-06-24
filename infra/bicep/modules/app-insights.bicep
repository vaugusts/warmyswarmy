// Application Insights Module
// APM solution for application performance monitoring and telemetry collection

param location string
param resourceSuffix string
param tags object
param logAnalyticsWorkspaceId string

var appInsightsName = 'appi-${resourceSuffix}'

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  tags: tags
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspaceId
    RetentionInDays: 90
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    IngestionMode: 'LogAnalytics'
    DisableIpMasking: false
    ForceCustomerStorageForProfiler: false
  }
}

// Alert rule for high request failure rate
resource failureRateAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-${appInsightsName}-failure-rate'
  location: 'global'
  tags: tags
  properties: {
    description: 'Alert when request failure rate exceeds 5%'
    severity: 2
    enabled: true
    scopes: [appInsights.id]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'Percentage server errors'
          metricName: 'server/exceptionsPerSecond'
          operator: 'GreaterThan'
          threshold: 0.05
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: []
  }
}

output appInsightsId string = appInsights.id
output appInsightsName string = appInsights.name
output instrumentationKey string = appInsights.properties.InstrumentationKey
output appId string = appInsights.properties.AppId
