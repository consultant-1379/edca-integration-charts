# COPYRIGHT Ericsson 2021
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.

*** Settings ***
Library           Collections
Library           RequestsLibrary
Library           String
Library           KubeLibrary


*** Keywords ***
List services by label
    [Arguments]  ${namespace}  ${label}
    @{namespace_services}=  Get Services In Namespace    ${namespace}  ${label}
    Should Be True  len(@{namespace_services}) == 1

Test Pod Status
    [Arguments]   ${namespace}   ${name_pattern}   ${replica_count}
    @{namespace_pods}=    get_pod_names_in_namespace  ${name_pattern}    ${namespace}
    ${num_of_pods}=    Get Length    ${namespace_pods}
    Should Be True    ${num_of_pods} == ${replica_count}  Number of running pods ${num_of_pods}
    FOR    ${pod}    IN    @{namespace_pods}
    ${status}=    get_pod_status_in_namespace    ${pod}    ${namespace}
    Should Be True     '${status}'=='Running'
    END

List cron jobs with label
    [Arguments]  ${namespace}  ${label}
    @{namespace_cron_jobs}=  Get Cron Jobs In Namespace  ${namespace}   ${label}
    Length Should Be  ${namespace_cron_jobs}  1


List jobs with label
    [Arguments]  ${job_name}  ${namespace}  ${label}
    @{namespace_jobs}=  Get Jobs In Namespace    ${job_name}  ${namespace}  ${label}
    Log  \nList labels in job ${job_name}:  console=True
    Length Should Be  ${namespace_jobs}  1
    

List all deployments in namespace
    [Arguments]  ${namespace}  ${label}  ${replicas}
    Log  ${label}  console=True
    Log  ${replicas}  console=True
    @{namespace_deployments}=  Get Deployments In Namespace   .*  ${namespace}   ${label}
    # Length Should Be  ${namespace_deployments}  1

    Log  ${namespace_deployments[0]}
    Should Be True  ${namespace_deployments[0].status.replicas} == ${replicas}
