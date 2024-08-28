#*******************************************************************************
# COPYRIGHT Ericsson 2020
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
...    Summary: Test suite for ADP IAM and API Gateway integration on EDCA
...
...    Owner: rishabh.kanhaiya@wipro.com (ZKANRIS)
...
...    Test cases included as part of this suites are;
...    EO_API_Gateway - Check the status of eric-eo-api-gateway.

Library           Collections
Library           RequestsLibrary
Library           String
Library           KubeLibrary
Resource          ${CURDIR}/../variables/EDCA_Common_Variables.robot

*** Keywords ***
Test Pod Status
        [Arguments]     ${name_pattern}
        @{namespace_pods}=    get_pod_names_in_namespace  ${name_pattern}    ${namespace}
        ${num_of_pods}=    Get Length    ${namespace_pods}
        Should Be True    ${num_of_pods} >= 1    No pods matching "${name_pattern}" found
        FOR    ${pod}    IN    @{namespace_pods}
        ${status}=    get_pod_status_in_namespace    ${pod}    ${namespace}
        Should Be True     '${status}'=='Running'
        END
       
*** Test Cases ***
Test_Case - Check the status of IAM & eric-eo-api-gateway
        [Tags]  Pod
        [Documentation]    Verify the Pod status in the provided namespace.
        ...    1. Connect the cluster.
        ...    2. Check for ${pod} pod status in namespace ${namespace}.
        ...    3. Pod shall be up and running. Total number of pods shall be equal to ready pods.       
        FOR  ${name}  IN  @{namepattern}
        Test Pod Status  ${name}
        END
