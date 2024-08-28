#*******************************************************************************
# COPYRIGHT Ericsson 2020
#
#
#
# The copyright to the computer program(s) herein is the property of
#
# Ericsson Inc. The programs may be used and/or copied only with written
#
# permission from Ericsson Inc. or in accordance with the terms and
#
# conditions stipulated in the agreement/contract under which the
#
# program(s) have been supplied.
#
#********************************************************************************

*** Settings ***
Documentation
...    Summary: Test suite for Catalog-Service,MinIo and PM-Server integration on EDCA
...
...    Owner: prasanth.s95@wipro.com (ZSPXAXR)
...
...    Test cases included as part of this suites are;
...    Catalog_Service_Testing_001 - Check the status of eric-edca-catalog.
...    MinIo_Testing_001 - Check the status of eric-data-object-storage-mn.
...    MinIo_Testing_002 - Check for eric-data-object-storage-mn Pods have enough replicas.
...    PM_Server_Testing_001 - Check the status of eric-pm-server.

Library           Collections
Library           RequestsLibrary
Library           String
Library           KubeLibrary
Resource          ${CURDIR}/../variables/EDCA_Common_Variables.robot

*** Keywords ***
Testing Catalog-Service Pod status
        [Arguments]     ${name_pattern}=eric-edca-catalog        ${num_of_pods}=1        ${pod}=eric-edca-catalog
        @{namespace_pods}=    get_pod_names_in_namespace  ${name_pattern}    ${namespace}
        ${num_of_pods}=    Get Length    ${namespace_pods}
        Should Be True    ${num_of_pods} >= 1    No pods matching "${name_pattern}" found
        FOR    ${pod}    IN    @{namespace_pods}
        ${status}=    get_pod_status_in_namespace    ${pod}    ${namespace}
        Should Be True     '${status}'=='Running'
        END

Testing MinIo Pod Status
        [Arguments]     ${name_pattern}=eric-data-object-storage-mn        ${num_of_pods}=4        ${pod}=eric-data-object-storage-mn
        @{namespace_pods}=    get_pod_names_in_namespace  ${name_pattern}    ${namespace}
        ${num_of_pods}=    Get Length    ${namespace_pods}
        Should Be True    ${num_of_pods} >= 3    No pods matching "${name_pattern}" found
        FOR    ${pod}    IN    @{namespace_pods}
        ${status}=    get_pod_status_in_namespace    ${pod}    ${namespace}
        Should Be True     '${status}'=='Running'
        END

Testing MinIo Pods have enough replicas
        [Arguments]     ${name_pattern}=eric-data-object-storage-mn        ${num_of_pods}=4        ${pod}=eric-data-object-storage-mn   ${pod_replicas}=5
        @{namespace_pods}=    get_pod_names_in_namespace  ${name_pattern}    ${namespace}
        ${count}=    Get Length   ${namespace_pods}
        Should Be True    ${count} == ${pod_replicas}

Testing PM-Server Pod status
        [Arguments]     ${name_pattern}=eric-pm-server        ${num_of_pods}=1        ${pod}=eric-pm-server
        @{namespace_pods}=    get_pod_names_in_namespace  ${name_pattern}    ${namespace}
        ${num_of_pods}=    Get Length    ${namespace_pods}
        Should Be True    ${num_of_pods} >= 1    No pods matching "${name_pattern}" found
        FOR    ${pod}    IN    @{namespace_pods}
        ${status}=    get_pod_status_in_namespace    ${pod}    ${namespace}
        Should Be True     '${status}'=='Running'
        END

*** Test Cases ***
Catalog_Service_Testing_001 - Check the status of eric-edca-catalog
        [Tags]  Pod
        [Documentation]    Verify the Catalog-Service status in the provided namespace.
        ...    1. Connect the cluster.
        ...    2. Check for ${pod} pod status in namespace ${namespace}.
        ...    3. Pod shall be up and running. Total number of pods shall be equal to ready pods.
		Log	Waiting for PODS to come up!! Waiting time 240s..
		Sleep	240s
        Testing Catalog-Service Pod status

MinIo_Testing_001 - Check the status of eric-data-object-storage-mn
        [Tags]  Pod
        [Documentation]    Verify the MinIo status in the provided namespace.
        ...    1. Connect the cluster.
        ...    2. Check for ${pod} pod status in namespace ${namespace}.
        ...    3. Pod shall be up and running. Total number of pods shall be equal to ready pods.
        Testing MinIo Pod Status

MinIo_Testing_002 - Check for eric-data-object-storage-mn Pods have enough replicas
        [Tags]  Pod
        [Documentation]    Verify the replicas for MinIo in the provided namespace.
        ...    1. Connect the cluster.
        ...    2. Check for ${pod} pod status in namespace ${namespace}.
        ...    3. DRD Kafka Pod shall have enough replica's
        Testing MinIo Pods have enough replicas

PM_Server_Testing_001 - Check the status of eric-pm-server
        [Tags]  Pod
        [Documentation]    Verify the PM-Server status in the provided namespace.
        ...    1. Connect the cluster.
        ...    2. Check for ${pod} pod status in namespace ${namespace}.
        ...    3. Pod shall be up and running. Total number of pods shall be equal to ready pods.
        Testing PM-Server Pod status

