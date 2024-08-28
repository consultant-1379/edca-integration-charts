*** comments ***
COPYRIGHT Ericsson 2020-2021 -
 The copyright to the computer program(s) herein is the property of
 Ericsson Inc. The programs may be used and/or copied only with written
 permission from Ericsson Inc. or in accordance with the terms and
 conditions stipulated in the agreement/contract under which the
 program(s) have been supplied.

*** Settings ***
Library    SSHLibrary
Library    OperatingSystem
Library    String
Suite Setup    Open Connection And Log In
Suite Teardown    Close All Connections

*** Variables ***
${HOST} 
${USERNAME}
${PASSWORD}
${NameSpace}
${cc-NameSpace}     cc-sim
${drg-NameSpace}    drg-sim

*** Keywords ***
Open Connection And Log In
   Open Connection     ${HOST}
   Login               ${USERNAME}        ${PASSWORD}

Return PodName
    [Arguments]    ${objectType}    ${serviceName}    ${nameSpace}
    ${ContainerName}=    Execute Command  kubectl get ${objectType} -o=name -n ${nameSpace} | grep ${serviceName}
    [Return]    ${ContainerName}

CC CleanupSteps
    Execute Command    kubectl exec ${dbPodName} -n ${NameSpace} -- bash -c "psql -U postgres -d catalog -c 'TRUNCATE bulk_data_repository, data_collector, data_provider_type, data_space, file_format, message_bus, notification_topic RESTART IDENTITY CASCADE;'"
    Execute Command    kubectl exec ${bdrPodName} -n ${NameSpace} -c manager -- bash -c "mc rm -r --force osmn/pm-data"

DRG CleanupSteps
    Execute Command    kubectl exec ${dbPodName} -n ${NameSpace} -- bash -c "psql -U postgres -d catalog -c 'TRUNCATE bulk_data_repository, data_collector, data_provider_type, data_space, file_format, message_bus, notification_topic RESTART IDENTITY CASCADE;'"
    Execute Command    kubectl exec ${bdrPodName} -n ${NameSpace} -c manager -- bash -c "mc rm --recursive --force osmn/pm-data"
    Execute Command    kubectl exec ${drgPodName} -n ${drg-NameSpace} -- sh -c "rm -rf minio_downloads"


*** comments ***

*** Test Cases ***
Setup for testEnv
    [Documentation]    This test is to setup initial env for the test variables
    ${bdrPodName}=    Return PodName    objectType=pod    serviceName=eric-data-object-storage-mn-mgt    nameSpace=${NameSpace}
    Set Global Variable    ${bdrPodName}
    ${ccPodName}=    Return PodName    objectType=pod    serviceName=collector    nameSpace=${cc-NameSpace}
    Set Global Variable    ${ccPodName}
    ${dbPodName}=   Return PodName    objectType=pod    serviceName=catalog-db-0   nameSpace=${NameSpace}
    Set Global Variable    ${dbPodName}
    ${drgPodName}=   Return PodName    objectType=pod    serviceName=drg-simulator   nameSpace=${drg-NameSpace}
    Set Global Variable    ${drgPodName}

68426_EDCA_BDR_Functional_TC_03 - Verify default users and policies
    [Documentation]    This testcase is to verify the default users and policies available in bdr.
    ${usersList}    Create List    ccuser    drguser
    ${policyList}    Create List    readuserpolicy    writeuserpolicy
    FOR    ${user}    IN    @{usersList}
    ${output}=          Execute Command     kubectl exec ${bdrPodName} -n ${NameSpace} -c manager -- bash -c "mc admin user list osmn/ --json | grep ${user}"
    ${jsonData}=    Evaluate    json.loads('''${output}''')    json
    Should be Equal    ${jsonData['accessKey']}    ${user}
    Should be Equal    ${jsonData['userStatus']}    enabled
    END
    FOR    ${policy}    IN    @{policyList}
    ${output}=          Execute Command     kubectl exec ${bdrPodName} -n ${NameSpace} -c manager -- bash -c "mc admin policy list osmn/ --json | grep ${policy}"
    ${jsonData}=    Evaluate    json.loads('''${output}''')    json
    Should be Equal    ${jsonData['policy']}    ${policy}
    Should be Equal    ${jsonData['status']}    success
    END

68426_EDCA_BDR_Functional_TC_06 - Verify creation of user with both read and write policy
    [Documentation]    This testcase is to verify the creation of new user with both read and write access(policy) in the bdr.
    ${accessKey}    Convert to String    testuser
    ${secretKey}    Convert to String    testuser123
    ${policyName}  Convert to String    readandwrite
    Create File    userpolicy.json    {"Version":"2012-10-17","Statement":[{"Sid":"writeandreaduserPolicy","Effect":"Allow","Action":["s3:PutObject","s3:ListBucket","s3:ListBucket","s3:GetObject","s3:GetBucketLocation","s3:GetBucketPolicy","s3:ListAllMyBuckets"],"Resource":["arn:aws:s3:::*"]}]}
    Put File    userpolicy.json
    ${podName}=    Replace String    ${bdrPodName}    pod/    ${EMPTY}
    Execute Command    kubectl cp /root/userpolicy.json ${NameSpace}/${podName}:/minio -c manager
    Execute Command    rm -f userpolicy.json
    Remove File    userpolicy.json
    Execute Command     kubectl exec ${bdrPodName} -n ${NameSpace} -c manager -- bash -c "mc admin user add osmn ${accessKey} ${secretKey}"
    ${output1}=          Execute Command     kubectl exec ${bdrPodName} -n ${NameSpace} -c manager -- bash -c "mc admin policy add osmn ${policyName} minio/userpolicy.json && mc admin policy set osmn ${policyName} user=${accessKey}"    
    ${output2}=          Execute Command     kubectl exec ${bdrPodName} -n ${NameSpace} -c manager -- bash -c "mc admin user list osmn --json | grep ${accessKey}"
    ${jsonData2}=    Evaluate    json.loads('''${output2}''')    json
    Should be Equal    ${jsonData2['accessKey']}    ${accessKey}
   # Should be Equal    ${jsonData2['policyName']}    ${policyName}
    Should be Equal    ${jsonData2['userStatus']}    enabled

68426_EDCA_BDR_Functional_TC_04 - Verify upload files to pre-defined bucket by user with write policy
    [Documentation]    This testcase is to verify the activity of uploading files to pre-defined bucket(pm-data) by user with write policy.
    ...    (i.e) making use of custom collector(write user)
    CC CleanupSteps
    Create File    NotificationData.json    {"topicName": "pm-data","dataCategory": "5G","dataSubCategory": ["CM_EXPORT"],"sourceType": ["pvid_3"],"topicEncoding": "JSON","topicSpecRef": "specref1","accessEndpoints": ["http://eric-oss-dmaap-kafka.${nameSpace}:9092"]}
    Create File    BulkDataRepository.json    {"name" : "BDR-entry24","nameSpace": "${nameSpace}","clusterName": "hoff135","accessEndpoints":["eric-data-object-storage-mn.${nameSpace}:9000/pm-data"]}
    Create File    MessageBus.json    {"name" : "message-bus14","nameSpace": "${nameSpace}","clusterName": "hoff135","accessEndpoints":["eric-oss-dmaap-kafka.${nameSpace}:9092"]}
    Create File    DataCollector.json    {"collectorId": "d65f5310-1593-4ae1-9f1d-ab9104180f01","controlEndpoint": "http://8.8.8.8:9090/end_point","name": "${nameSpace}_dc1"}
    Put File    NotificationData.json
    Put File    BulkDataRepository.json
    Put File    MessageBus.json
    Put File    DataCollector.json
    ${podName}=    Replace String    ${ccPodName}    pod/    ${EMPTY}
    Execute Command    kubectl exec ${ccPodName} -n ${cc-NameSpace} -- bash -c "rm -f test-data/pm-data/NotificationData.json && rm -f test-data/pm-data/BulkDataRepository.json && rm -f test-data/pm-data/MessageBus.json && rm -f test-data/pm-data/DataCollector.json"
    Execute Command    kubectl cp /root/NotificationData.json ${cc-NameSpace}/${podName}:./test-data/pm-data
    Execute Command    kubectl cp /root/BulkDataRepository.json ${cc-NameSpace}/${podName}:./test-data/pm-data
    Execute Command    kubectl cp /root/MessageBus.json ${cc-NameSpace}/${podName}:./test-data/pm-data
    Execute Command    kubectl cp /root/DataCollector.json ${cc-NameSpace}/${podName}:./test-data/pm-data
    Execute Command    rm -f NotificationData.json && rm -f BulkDataRepository.json && rm -f MessageBus.json && rm -f DataCollector.json
    Remove File    NotificationData.json
    Remove File    BulkDataRepository.json
    Remove File    MessageBus.json
    Remove File    DataCollector.json
    ${bucketContent}=          Execute Command     kubectl exec ${bdrPodName} -n ${NameSpace} -c manager -- bash -c "mc ls osmn/pm-data"
    Should be Empty    ${bucketContent}
    ${portCheck}=    Execute Command    kubectl exec ${ccPodName} -n ${cc-NameSpace} -- bash -c "pgrep -x java"
    Execute Command    kubectl exec ${ccPodName} -n ${cc-NameSpace} -- bash -c "kill -9 ${portCheck}"
    ${executionCheck}=    Execute Command    kubectl exec ${ccPodName} -n ${cc-NameSpace} -- bash -c "java -jar custom-collector.jar --spring.config.additional-location=config.properties --edca.nameSpace=${nameSpace} --edca.bdr.accesskey=ccuser --edca.bdr.secretkey=ccuser123 --edca.test.counter=1 --automation"
    log    ${executionCheck}
    ${fileCheck}=    Execute Command     kubectl exec ${bdrPodName} -n ${NameSpace} -c manager -- bash -c "mc ls osmn/pm-data | wc -l"
    Should Be Equal As Integers    ${fileCheck}    1

68426_EDCA_BDR_Functional_TC_07 - Verify upload files by user with write and read policy
    [Documentation]    This testcase is to verify the activity of uploading files to pre-defined bucket(pm-data) by user with both read & write policy.
    ...    (i.e) making use of custom collector(with the user created in testcase - 68426_EDCA_BDR_Functional_TC_06)
    CC CleanupSteps
    ${bucketContent}=          Execute Command     kubectl exec ${bdrPodName} -n ${NameSpace} -c manager -- bash -c "mc ls osmn/pm-data"
    Should be Empty    ${bucketContent}
    ${portCheck}=    Execute Command    kubectl exec ${ccPodName} -n ${cc-NameSpace} -- bash -c "pgrep -x java"
    Execute Command    kubectl exec ${ccPodName} -n ${cc-NameSpace} -- bash -c "kill -9 ${portCheck}"
    ${executionCheck}=    Execute Command    kubectl exec ${ccPodName} -n ${cc-NameSpace} -- bash -c "java -jar custom-collector.jar --spring.config.additional-location=config.properties --edca.nameSpace=${nameSpace} --edca.bdr.accesskey=testuser --edca.bdr.secretkey=testuser123 --edca.test.counter=1 --automation"
    ${fileCheck}=    Execute Command     kubectl exec ${bdrPodName} -n ${NameSpace} -c manager -- bash -c "mc ls osmn/pm-data | wc -l"
    Should Be Equal As Integers    ${fileCheck}    1

68426_EDCA_BDR_Negative_TC_03 - Verify upload of files by user that doesn't exist
    [Documentation]    This testcase is to verify the activity of uploading files to pre-defined bucket(pm-data) by a non-existing user.
    ...    (i.e) making use of custom collector(with the non-existing user)
    CC CleanupSteps
    ${bucketContent}=          Execute Command     kubectl exec ${bdrPodName} -n ${NameSpace} -c manager -- bash -c "mc ls osmn/pm-data"
    Should be Empty    ${bucketContent}
    ${portCheck}=    Execute Command    kubectl exec ${ccPodName} -n ${cc-NameSpace} -- bash -c "pgrep -x java"
    Execute Command    kubectl exec ${ccPodName} -n ${cc-NameSpace} -- bash -c "kill -9 ${portCheck}"
    ${executionCheck}=    Execute Command    kubectl exec ${ccPodName} -n ${cc-NameSpace} -- bash -c "java -jar custom-collector.jar --spring.config.additional-location=config.properties --edca.nameSpace=${nameSpace} --edca.bdr.accesskey=xyzuser --edca.bdr.secretkey=xyzuser123 --edca.test.counter=1 --automation"
    Should Contain    ${executionCheck}    Upload file = FAILED Access denied

68426_EDCA_BDR_Negative_TC_04 - Verify upload of files to bucket that doesn't exist
    [Documentation]    This testcase is to verify the activity of uploading files by a write user to non-existing bucket in bdr.
    ...    (i.e) making use of custom collector(with non-existing bucket details)
    CC CleanupSteps
    ${bucketContent}=          Execute Command     kubectl exec ${bdrPodName} -n ${NameSpace} -c manager -- bash -c "mc ls osmn/pm-data"
    Should be Empty    ${bucketContent}
    ${portCheck}=    Execute Command    kubectl exec ${ccPodName} -n ${cc-NameSpace} -- bash -c "pgrep -x java"
    Execute Command    kubectl exec ${ccPodName} -n ${cc-NameSpace} -- bash -c "kill -9 ${portCheck}"
    ${executionCheck}=    Execute Command    kubectl exec ${ccPodName} -n ${cc-NameSpace} -- bash -c "java -jar custom-collector.jar --spring.config.additional-location=config.properties --edca.nameSpace=${nameSpace} --edca.bdr.accesskey=ccuser --edca.bdr.secretkey=ccuser123 --edca.bdr.bucket=fm-data --edca.test.counter=1 --automation"
    Should Contain    ${executionCheck}    Bucket: fm-data DOES NOT EXIST

68426_EDCA_BDR_Negative_TC_05 - Verify upload of files to topic name that doesn't exist
    [Documentation]    This testcase is to verify the activity of sending notifications to non-existing topic in Kafka.
    ...    (i.e) making use of custom collector(with non-existing kafka topic details)
    CC CleanupSteps
    ${topicName}=  Generate Random String    6   [LOWER]
    # creating and copying a sample file(kafka notification metadata) to cc pod for testing
    Create File    NotificationData.json    {"topicName": "${topicName}","dataCategory": "5G","dataSubCategory": ["CM_EXPORT"],"sourceType": ["pvid_3"],"topicEncoding": "JSON","topicSpecRef": "specref1","accessEndpoints": ["http://eric-oss-dmaap-kafka.${nameSpace}:9092"]} 
    Put File    NotificationData.json
    ${podName}=    Replace String    ${ccPodName}    pod/    ${EMPTY}
    Execute Command    kubectl exec ${ccPodName} -n ${cc-NameSpace} -- bash -c "mv test-data/pm-data/NotificationData.json test-data/pm-data/NotificationData1.json"
    Execute Command    kubectl cp /root/NotificationData.json ${cc-NameSpace}/${podName}:./test-data/pm-data
    Remove File    NotificationData.json
    ${portCheck}=    Execute Command    kubectl exec ${ccPodName} -n ${cc-NameSpace} -- bash -c "pgrep -x java"
    Execute Command    kubectl exec ${ccPodName} -n ${cc-NameSpace} -- bash -c "kill -9 ${portCheck}"
    ${executionCheck}=    Execute Command    kubectl exec ${ccPodName} -n ${cc-NameSpace} -- bash -c "java -jar custom-collector.jar --spring.config.additional-location=config.properties --edca.nameSpace=${nameSpace} --edca.bdr.accesskey=ccuser --edca.bdr.secretkey=ccuser123 --edca.test.counter=1 --automation"
    Execute Command    kubectl exec ${ccPodName} -n ${cc-NameSpace} -- bash -c "rm test-data/pm-data/NotificationData.json"
    Execute Command    kubectl exec ${ccPodName} -n ${cc-NameSpace} -- bash -c "mv test-data/pm-data/NotificationData1.json test-data/pm-data/NotificationData.json"
    Should Contain    ${executionCheck}    {${topicName}=LEADER_NOT_AVAILABLE}

68426_EDCA_BDR_Negative_TC_06 - Verify create metadata from CC simulator with wrong details
    [Documentation]    This testcase is to verify the activity of creating metadata in catalog with wrong payload/details.
    ...    (i.e) making use of custom collector(with inappropriate content of Catalog data)
    CC CleanupSteps
    DRG CleanupSteps
    # creating and copying a sample file(catalog data) to cc pod for testing
    Create File    BulkDataRepository.json    {"bdrDetails":"test"}
    Put File    BulkDataRepository.json
    ${podName}=    Replace String    ${ccPodName}    pod/    ${EMPTY}
    Execute Command    kubectl exec ${ccPodName} -n ${cc-NameSpace} -- bash -c "mv test-data/pm-data/BulkDataRepository.json test-data/pm-data/BulkDataRepository1.json"
    Execute Command    kubectl cp /root/BulkDataRepository.json ${cc-NameSpace}/${podName}:./test-data/pm-data
    Remove File    BulkDataRepository.json
    ${portCheck}=    Execute Command    kubectl exec ${ccPodName} -n ${cc-NameSpace} -- bash -c "pgrep -x java"
    Execute Command    kubectl exec ${ccPodName} -n ${cc-NameSpace} -- bash -c "kill -9 ${portCheck}"
    ${executionCheck1}=    Execute Command    kubectl exec ${ccPodName} -n ${cc-NameSpace} -- bash -c "java -jar custom-collector.jar --spring.config.additional-location=config.properties --edca.nameSpace=${nameSpace} --edca.test.counter=1 --automation"
    Execute Command    kubectl exec ${ccPodName} -n ${cc-NameSpace} -- bash -c "rm test-data/pm-data/BulkDataRepository.json"
    Execute Command    kubectl exec ${ccPodName} -n ${cc-NameSpace} -- bash -c "mv test-data/pm-data/BulkDataRepository1.json test-data/pm-data/BulkDataRepository.json"
    Should Contain    ${executionCheck1}    Register File Format Information: failed with http response=400
    ${executionCheck2}=    Execute Command    kubectl exec ${ccPodName} -n ${cc-NameSpace} -- bash -c "java -jar custom-collector.jar --spring.config.additional-location=config.properties --edca.nameSpace=${nameSpace} --edca.bdr.accesskey=ccuser --edca.bdr.secretkey=ccuser123 --edca.bdr.host=http://xyz --edca.test.counter=1 --automation"
    Should Contain    ${executionCheck2}    Upload file = FAILED xyz: No address associated with hostname

68426_EDCA_BDR_Negative_TC_07 - Verify download of files by user that doesn't exist
    [Documentation]    This testcase is to verify the activity of downloading files from the bdr by a non-existing user.
    ...    (i.e) making use of drg simulator(with non-existing user details)
    DRG CleanupSteps
    ${accessKey}=  Generate Random String    6   [LOWER]
    Execute Command    kubectl exec ${drgPodName} -n ${drg-NameSpace} -- bash -c "cat auto.sh > auto1.sh && chmod +x auto1.sh && sed -i -r 's/CATALOG_URL\\=[a-zA-Z0-9].*$/CATALOG_URL=http\\:\\/\\/eric-edca-catalog.${NameSpace}\\:9590/g' auto1.sh && sed -i 's/drguser/${accessKey}/g' auto1.sh"
    ${ccLog}=    Execute Command    kubectl exec ${ccPodName} -n ${cc-NameSpace} -- bash -c "java -jar custom-collector.jar --spring.config.additional-location=config.properties --edca.nameSpace=${nameSpace} --edca.bdr.accesskey=ccuser --edca.bdr.secretkey=ccuser123 --edca.test.counter=1 --automation"
    ${appStatusId}=    Execute Command    kubectl exec ${drgPodName} -n ${drg-NameSpace} -- bash -c "pgrep -x java"
    Execute Command    kubectl exec ${drgPodName} -n ${drg-NameSpace} -- bash -c "kill -9 ${appStatusId}"
    ${executionCheck}=    Execute Command    kubectl exec ${drgPodName} -n ${drg-NameSpace} -- bash -c "timeout 20 ./auto1.sh"
    Should Contain    ${executionCheck}    Error in Bucket initialisation : Access denied
    ${fileCount}=    Execute Command    kubectl exec ${drgPodName} -n ${drg-NameSpace} -- bash -c "rm -f auto1.sh && find minio_downloads -name *.json | wc -l"
    Should Be Equal As Integers    ${fileCount}    0

68426_EDCA_BDR_Functional_TC_05 - Verify download files to pre-defined bucket by user with read policy
    [Documentation]    This testcase is to verify the activity of downloading files from the bdr by a read user.
    ...    (i.e) making use of drg simulator(with read user/default user details)
    DRG CleanupSteps
    Execute Command    kubectl exec ${drgPodName} -n ${drg-NameSpace} -- bash -c "cat auto.sh > auto1.sh && chmod +x auto1.sh && sed -i -r 's/CATALOG_URL\\=[a-zA-Z0-9].*$/CATALOG_URL=http\\:\\/\\/eric-edca-catalog.${NameSpace}\\:9590/g' auto1.sh"
    ${appStatusId}=    Execute Command    kubectl exec ${drgPodName} -n ${drg-NameSpace} -- bash -c "pgrep -x java"
    Execute Command    kubectl exec ${drgPodName} -n ${drg-NameSpace} -- bash -c "kill -9 ${appStatusId}"
    ${ccLog}=    Execute Command    kubectl exec ${ccPodName} -n ${cc-NameSpace} -- bash -c "java -jar custom-collector.jar --spring.config.additional-location=config.properties --edca.nameSpace=${nameSpace} --edca.bdr.accesskey=ccuser --edca.bdr.secretkey=ccuser123 --edca.test.counter=1 --automation"
    ${executionCheck}=    Execute Command    kubectl exec ${drgPodName} -n ${drg-NameSpace} -- bash -c "timeout 14 ./auto1.sh"
    ${fileCount}=    Execute Command    kubectl exec ${drgPodName} -n ${drg-NameSpace} -- bash -c "rm -f auto1.sh && find minio_downloads -name *.json | wc -l"
    Should Be Equal As Integers    ${fileCount}    1

68426_EDCA_BDR_Functional_TC_08 - Verify download files by user with write and read policy
    [Documentation]    This testcase is to verify the activity of downloading files from the bdr by a user with both read and write policy.
    ...    (i.e) making use of drg simulator(with user having read & write access)
    DRG CleanupSteps
    Execute Command    kubectl exec ${drgPodName} -n ${drg-NameSpace} -- bash -c "cat auto.sh > auto1.sh && chmod +x auto1.sh && sed -i -r 's/CATALOG_URL\\=[a-zA-Z0-9].*$/CATALOG_URL=http\\:\\/\\/eric-edca-catalog.${NameSpace}\\:9590/g' auto1.sh && sed -i 's/drguser/testuser/g' auto1.sh"
    Execute Command    kubectl exec ${ccPodName} -n ${cc-NameSpace} -- bash -c "java -jar custom-collector.jar --spring.config.additional-location=config.properties --edca.nameSpace=${nameSpace} --edca.bdr.accesskey=ccuser --edca.bdr.secretkey=ccuser123 --edca.test.counter=1 --automation"
    ${appStatusId}=    Execute Command    kubectl exec ${drgPodName} -n ${drg-NameSpace} -- bash -c "pgrep -x java"
    Execute Command    kubectl exec ${drgPodName} -n ${drg-NameSpace} -- bash -c "kill -9 ${appStatusId}"
    ${executionCheck}=    Execute Command    kubectl exec ${drgPodName} -n ${drg-NameSpace} -- bash -c "timeout 14 ./auto1.sh"
    ${fileCount}=    Execute Command    kubectl exec ${drgPodName} -n ${drg-NameSpace} -- bash -c "rm -f auto1.sh && find minio_downloads -name *.json | wc -l"
    Should Be Equal As Integers    ${fileCount}    1

68426_EDCA_BDR_Negative_TC_09 - Verify download of files from topic name that doesn't exist
    [Documentation]    This testcase is to verify the activity of downloading files by getting notifications with non-existing kafka topic.
    ...    (i.e) making use of drg simulator(with non-existing topic details)
    DRG CleanupSteps
    ${topicName}=  Generate Random String    6   [LOWER]
    # creating and copying a sample file to drg pod(kafka notification detail) for testing
    Create File    NotificationTopic.json    {"messageBusId":31,"name":"${topicName}","encoding":"JSON","specificationReference":"specref1"}
    Put File    NotificationTopic.json
    ${podName}=    Replace String    ${ccPodName}    pod/    ${EMPTY}
    Execute Command    kubectl exec ${ccPodName} -n ${cc-NameSpace} -- bash -c "mv test-data/pm-data/NotificationTopic.json test-data/pm-data/NotificationTopic1.json"
    Execute Command    kubectl cp /root/NotificationTopic.json ${cc-NameSpace}/${podName}:./test-data/pm-data
    Remove File    NotificationTopic.json
    Execute Command    kubectl exec ${ccPodName} -n ${cc-NameSpace} -- bash -c "java -jar custom-collector.jar --spring.config.additional-location=config.properties --edca.nameSpace=${nameSpace} --edca.bdr.accesskey=ccuser --edca.bdr.secretkey=ccuser123 --edca.test.counter=1 --automation"
    ${appStatusId}=    Execute Command    kubectl exec ${drgPodName} -n ${drg-NameSpace} -- bash -c "pgrep -x java"
    Execute Command    kubectl exec ${drgPodName} -n ${drg-NameSpace} -- bash -c "kill -9 ${appStatusId}"
    Execute Command    kubectl exec ${drgPodName} -n ${drg-NameSpace} -- bash -c "cat auto.sh > auto1.sh && chmod +x auto1.sh && sed -i -r 's/CATALOG_URL\\=[a-zA-Z0-9].*$/CATALOG_URL=http\\:\\/\\/eric-edca-catalog.${NameSpace}\\:9590/g' auto1.sh"
    ${executionCheck}=    Execute Command    kubectl exec ${drgPodName} -n ${drg-NameSpace} -- bash -c "timeout 14 ./auto1.sh"
    Execute Command    kubectl exec ${drgPodName} -n ${drg-NameSpace} -- bash -c "rm -f auto1.sh"
    Execute Command    kubectl exec ${ccPodName} -n ${cc-NameSpace} -- bash -c "rm -f test-data/pm-data/NotificationTopic.json"
    Execute Command    kubectl exec ${ccPodName} -n ${cc-NameSpace} -- bash -c "mv test-data/pm-data/NotificationTopic1.json test-data/pm-data/NotificationTopic.json"
    Should Contain    ${executionCheck}    {${topicName}=LEADER_NOT_AVAILABLE}

68426_EDCA_BDR_Negative_TC_08 - Verify download of files from bucket that doesn't exist
    [Documentation]    This testcase is to verify the activity of downloading files from a non-existing bucket from bdr.
    ...    (i.e) making use of drg simulator(with non-existing bucket details on bdr)
    DRG CleanupSteps
    Execute Command    kubectl exec ${ccPodName} -n ${cc-NameSpace} -- bash -c "java -jar custom-collector.jar --spring.config.additional-location=config.properties --edca.nameSpace=${nameSpace} --edca.bdr.accesskey=ccuser --edca.bdr.secretkey=ccuser123 --edca.test.counter=1 --automation"
    Execute Command    kubectl exec ${bdrPodName} -n ${NameSpace} -c manager -- bash -c "mc rb --force osmn/pm-data"
    ${appStatusId}=    Execute Command    kubectl exec ${drgPodName} -n ${drg-NameSpace} -- bash -c "pgrep -x java"
    Execute Command    kubectl exec ${drgPodName} -n ${drg-NameSpace} -- bash -c "kill -9 ${appStatusId}"
    Execute Command    kubectl exec ${drgPodName} -n ${drg-NameSpace} -- bash -c "cat auto.sh > auto1.sh && chmod +x auto1.sh && sed -i -r 's/CATALOG_URL\\=[a-zA-Z0-9].*$/CATALOG_URL=http\\:\\/\\/eric-edca-catalog.${NameSpace}\\:9590/g' auto1.sh"
    ${executionCheck}=    Execute Command    kubectl exec ${drgPodName} -n ${drg-NameSpace} -- bash -c "timeout 14 ./auto1.sh"
    Execute Command    kubectl exec ${bdrPodName} -n ${NameSpace} -c manager -- bash -c "mc mb osmn/pm-data"
    Should Contain    ${executionCheck}    Bucket doesn't exist
    ${fileCount}=    Execute Command    kubectl exec ${drgPodName} -n ${drg-NameSpace} -- bash -c "rm -f auto1.sh & find minio_downloads -name *.json | wc -l"
    Should Be Equal As Integers    ${fileCount}    0

68426_EDCA_BDR_Negative_TC_10 - Verify Get metadata using DRG simulator with wrong details
    [Documentation]    This testcase is to verify the activity of getting data from catalog service(Invalid REST endpoints).
    ...    (i.e) making use of drg simulator(with inappropriate catalog config details)
    DRG CleanupSteps
    Execute Command    kubectl exec ${ccPodName} -n ${cc-NameSpace} -- bash -c "java -jar custom-collector.jar --spring.config.additional-location=config.properties --edca.nameSpace=${nameSpace} --edca.bdr.accesskey=ccuser --edca.bdr.secretkey=ccuser123 --edca.test.counter=1 --automation"
    Execute Command    kubectl exec ${drgPodName} -n ${drg-NameSpace} -- bash -c "cat auto.sh > auto1.sh && chmod +x auto1.sh && sed -i -r 's/CATALOG_URL\\=[a-zA-Z0-9].*$/CATALOG_URL=http\\:\\/\\/eric-edca-catalog.${NameSpace}\\:9590/g' auto1.sh && sed -i 's/\\/catalog/\\/test/g' auto1.sh"
    ${appStatusId}=    Execute Command    kubectl exec ${drgPodName} -n ${drg-NameSpace} -- bash -c "pgrep -x java"
    Execute Command    kubectl exec ${drgPodName} -n ${drg-NameSpace} -- bash -c "kill -9 ${appStatusId}"
    ${executionCheck}=    Execute Command    kubectl exec ${drgPodName} -n ${drg-NameSpace} -- bash -c "timeout 14 ./auto1.sh"
    Execute Command    kubectl exec ${drgPodName} -n ${drg-NameSpace} -- bash -c "rm -f auto1.sh"
    Should Contain    ${executionCheck}    HTTP Status 404