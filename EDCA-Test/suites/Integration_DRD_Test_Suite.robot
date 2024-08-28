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
...    Summary: Test suite for DRD integration on EDCA
...
...    Owner: prasanth.s95@wipro.com (ZSPXAXR)
...
...    Test cases included as part of this suites are;
...    DRD_Testing_Suite_001 - Check the status of eric-oss-dmaap.
...    DRD_Testing_Suite_002 - Check the status of eric-oss-dmaap-kafka.
...    DRD_Testing_Suite_003 - Check for eric-oss-dmaap-kafka Pods have enough replicas.
...    DRD_Testing_Suite_004 - Check the status of eric-data-coordinator-zk.
...    DRD_Testing_Suite_005 - Check for eric-data-coordinator-zk Pods have enough replicas.

Library           Collections
Library           RequestsLibrary
Library           String
Library           KubeLibrary
Resource          ${CURDIR}/../variables/EDCA_Common_Variables.robot

*** Keywords ***
Testing DMaaP Pod status
        [Arguments]     ${name_pattern}=eric-oss-dmaap-0        ${num_of_pods}=1        ${pod}=eric-oss-dmaap-0
        @{namespace_pods}=    get_pod_names_in_namespace  ${name_pattern}    ${namespace}
        ${num_of_pods}=    Get Length    ${namespace_pods}
        Should Be True    ${num_of_pods} >= 1    No pods matching "${name_pattern}" found
        FOR    ${pod}    IN    @{namespace_pods}
        ${status}=    get_pod_status_in_namespace    ${pod}    ${namespace}
        Should Be True     '${status}'=='Running'
        END

DRD Kafka Pod Status
        [Arguments]     ${name_pattern}=eric-oss-dmaap-kafka        ${num_of_pods}=3        ${pod}=eric-oss-dmaap-kafka
        @{namespace_pods}=    get_pod_names_in_namespace  ${name_pattern}    ${namespace}
        ${num_of_pods}=    Get Length    ${namespace_pods}
        Should Be True    ${num_of_pods} >= 3    No pods matching "${name_pattern}" found
        FOR    ${pod}    IN    @{namespace_pods}
        ${status}=    get_pod_status_in_namespace    ${pod}    ${namespace}
        Should Be True     '${status}'=='Running'
        END

DRD Kafka Pods have enough replicas
        [Arguments]     ${name_pattern}=eric-oss-dmaap-kafka        ${num_of_pods}=3        ${pod}=eric-oss-dmaap-kafka	${pod_replicas}=3
        @{namespace_pods}=    get_pod_names_in_namespace  ${name_pattern}    ${namespace}
        ${count}=    Get Length   ${namespace_pods}
        Should Be True    ${count} == ${pod_replicas}

DRD Kafka ZooKeeper Pod Status
        [Arguments]     ${name_pattern}=eric-oss-dmaap-kafka        ${num_of_pods}=3        ${pod}=eric-data-coordinator-zk
        @{namespace_pods}=    get_pod_names_in_namespace  ${name_pattern}    ${namespace}
        ${num_of_pods}=    Get Length    ${namespace_pods}
        Should Be True    ${num_of_pods} >= 3    No pods matching ${name_pattern} found
        FOR    ${pod}    IN    @{namespace_pods}
        ${status}=    get_pod_status_in_namespace    ${pod}    ${namespace}
        Should Be True     '${status}'=='Running'
        END

DRD Kafka ZooKeeper Pods have enough replicas
        [Arguments]     ${name_pattern}=eric-oss-dmaap-kafka        ${num_of_pods}=3        ${pod}=eric-data-coordinator-zk     ${pod_replicas}=3
        @{namespace_pods}=    get_pod_names_in_namespace  ${name_pattern}    ${namespace}
        ${count}=    Get Length   ${namespace_pods}
        Should Be True    ${count} == ${pod_replicas}

*** Test Cases ***
DRD_Testing_Suite_001 - Check the status of eric-oss-dmaap
        [Tags]  Pod
        [Documentation]    Verify the DMaaP status in the provided namespace.
        ...    1. Connect the cluster.
        ...    2. Check for ${pod} pod status in namespace ${namespace}.
        ...    3. Pod shall be up and running. Total number of pods shall be equal to ready pods.
        Testing DMaaP Pod status

DRD_Testing_Suite_002 - Check the status of eric-oss-dmaap-kafka
        [Tags]  Pod
                        [Documentation]    Verify the Kafka status in the provided namespace.
        ...    1. Connect the cluster.
        ...    2. Check for ${pod} pod status in namespace ${namespace}.
        ...    3. Pod shall be up and running. Total number of pods shall be equal to ready pods.
        DRD Kafka Pod Status

DRD_Testing_Suite_003 - Check for eric-oss-dmaap-kafka Pods have enough replicas.
        [Tags]  Pod
        [Documentation]    Verify the replicas for DRD Kafka in the provided namespace.
        ...    1. Connect the cluster.
        ...    2. Check for ${pod} pod status in namespace ${namespace}.
        ...    3. DRD Kafka Pod shall have enough replica's
        DRD Kafka Pods have enough replicas

DRD_Testing_Suite_004 - Check the status of eric-data-coordinator-zk.
        [Tags]  Pod
        [Documentation]    Verify the ZooKeeper status in the provided namespace.
        ...    1. Connect the cluster.
        ...    2. Check for ${pod} pod status in namespace ${namespace}.
        ...    3. Pod shall be up and running. Total number of pods shall be equal to ready pods.
        DRD Kafka Zookeeper Pod status

DRD_Testing_Suite_005 - Check for eric-data-coordinator-zk Pods have enough replicas.
        [Tags]  Pod
        [Documentation]    Verify the replicas for DRD ZooKeeper in the provided namespace.
        ...    1. Connect the cluster.
        ...    2. Check for ${pod} pod status in namespace ${namespace}.
        ...    3. DRD ZooKeeper Pod shall have enough replica's
        DRD Kafka ZooKeeper Pods have enough replicas

