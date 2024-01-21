<#
.SYNOPSIS
    Invoke Pipelines
.DESCRIPTION
    This script will start the build pipelines in Azure DevOps
.EXAMPLE
    Example syntax for running the script or function
    PS C:\> Invoke-ADOBuild
.NOTES
    Filename: Invoke-BuildPipeline.ps1
    Author: Praveen M
    Created date: 2024-01-21
    Version 1.0  
#>
Function Invoke-ADOBuild{
    [CmdletBinding()]
    Param(
            [Parameter(Mandatory)]
            [String] $PAT,
            [String] $ADOOrganization,
            [String] $ADOProjectName,
            [String] $PipelineName
    )
# Construct the Authorization header using Personal Access Token (PAT)
$ADOAuthHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PAT)")) }
# Define the REST API endpoint to fetch all Pipelines in the specified Azure DevOps project
$Uri= "https://dev.azure.com/$($ADOOrganization)/$($ADOProjectName)/_apis/pipelines?api-version=6.0-preview.1"
# Invoke the Azure DevOps REST API to get the list of Pipelines
$Pipelines = Invoke-RestMethod -Uri $Uri -Headers $ADOAuthHeader -Method get -ContentType "application/json"
# Filter Pipelines based on the provided pipeline name
$ADO_PipelineLists = $Pipelines.value  | Where-Object {$_.Name -like "$PipelineName*"}
# Iterate through each matching pipeline
ForEach($Pipeline in $ADO_PipelineLists)
{  
   # Convert the pipeline details to JSON format
   $Body = $Pipeline | ConvertTo-Json -Depth 10
   # Define the REST API endpoint to trigger a run for the selected pipeline
   $Pipeline_URL = "https://dev.azure.com/$($ADOOrganization)/$($ADOProjectName)/_apis/pipelines/$($pipeline.id)/runs?api-version=6.0-preview.1"
   $Rest_Output=Invoke-RestMethod -Uri $Pipeline_URL -Method post -ContentType application/json -Body $body -Header $ADOAuthHeader  
   # Display relevant information about the triggered pipeline run
   $Rest_Output | Select-Object @{N="Pipeline Name";E={($_).Pipeline.Name}},  @{N="PipelineFolder";E={($_).Pipeline.Folder}},State,@{N="Build Name";E={($_).Name}} ,@{N="Branch Name";E={($_).resources.repositories.self.refname}}, @{N="Pipeline URL";E={($_).Pipeline.URL}},@{N="Pipeline Build URL";E={($_).URL}} | Format-List  
}
}

