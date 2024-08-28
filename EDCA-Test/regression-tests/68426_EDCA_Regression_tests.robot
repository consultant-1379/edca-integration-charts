*** comments ***
COPYRIGHT Ericsson 2020-2021 -
 The copyright to the computer program(s) herein is the property of
 Ericsson Inc. The programs may be used and/or copied only with written
 permission from Ericsson Inc. or in accordance with the terms and
 conditions stipulated in the agreement/contract under which the
 program(s) have been supplied.

*** Settings ***
Library    SSHLibrary
Library    String
Suite Setup    Open Connection And Log In
Suite Teardown    Close All Connections

*** Variables ***
${HOST}
${USERNAME}
${PASSWORD}
${NameSpace}

*** Keywords ***
Open Connection And Log In
   Open Connection     ${HOST}
   Login               ${USERNAME}        ${PASSWORD}
   
Return PodName
    [Arguments]    ${objectType}    ${serviceName}
    ${ContainerName}=    Execute Command  kubectl get ${objectType} -o=name -n ${NameSpace} | grep ${serviceName}
    [Return]    ${ContainerName}
    

*** comments ***
Dmaap test cases needs to be monitored during performance test cases for time being taken for completion of tasks.

*** Test Cases ***

Setup for testEnv
    [Documentation]    This test is to setup initial env for the test variables
    ${bdrPodName}=    Return PodName    objectType=pod    serviceName=eric-data-object-storage-mn-mgt
    Set Global Variable    ${bdrPodName}
    ${dmaapService}=      Return PodName    objectType=svc   serviceName="dmaap$"
    Set Global Variable    ${dmaapService}
    ${zkServiceName}=    Return PodName    objectType=svc   serviceName="zk$"
    Set Global Variable    ${zkServiceName}
    ${kafkaPodName}=   Return PodName    objectType=pod   serviceName="dmaap-kafka" -m 1
    Set Global Variable    ${kafkaPodName}

68426_EDCA_BDR_Functional_TC_01 - Verify Listing pre-defined buckets
    [Documentation]    This testcase is to verify the pre-existing/pre-defined buckets available in Bulk Data Repository
    @{BucketList}=    Create List    mixed-data/    pm-data/
    FOR    ${bucketName}    IN    @{BucketList}
        ${output1}=          Execute Command     kubectl exec ${bdrPodName} -n ${NameSpace} -c manager -- bash -c "mc ls osmn/ --json | grep ${bucketName}"
        ${jsonData1}=    Evaluate    json.loads('''${output1}''')    json
        Should be Equal    ${jsonData1['key']}    ${bucketName}
    END
    
68426_EDCA_BDR_Functional_TC_02 - Verify Listing data objects of pre-defined buckets
    [Documentation]    This testcase is to check the contents of the pre-defined buckets available in Bulk Data Repository
    ${BucketList}=    Create List    pm-data    mixed-data
    FOR    ${bucketName}    IN    @{BucketList}
    ${objectList}=    Execute Command     kubectl exec ${bdrPodName} -n ${NameSpace} -- bash -c "mc ls osmn/${bucketName} | wc -l"
    Should Be Equal As Integers    ${objectList}    0
    END
    
68426_EDCA_DRD_Functional_TC_01 - Verify all default topics available using Dmaap endpoint
    [Documentation]    This testcases is to verify the default/pre-defined topics available in Dmaap
    ${serviceName}=     Replace String    ${dmaapService}    service/    ${EMPTY}
    ${servicePort}=     Execute Command   kubectl get ${dmaapService} -o jsonpath='{.spec.ports[0].targetPort}' -n ${NameSpace}
    Start Command  kubectl exec ${kafkaPodName} -n ${NameSpace} -- bash -c "curl -X GET http://${serviceName}.${NameSpace}:${servicePort}/topics"
    ${output}=     Read Command Output    return_rc=True     return_stdout=True
    Should Be Equal As Integers    ${output[1]}    0
    Log    ${output[0]}
    
68426_EDCA_DRD_Functional_TC_02 - Verify all default topics available in kafka
    [Documentation]    This testcase is to verify the default/pre-defined topics available in kafka endpoint
    ${serviceName}=     Replace String    ${zkServiceName}    service/    ${EMPTY}
    ${servicePort}=     Execute Command   kubectl get ${zkServiceName} -o jsonpath='{.spec.ports[?(@.name=="client")].targetPort}' -n ${NameSpace}
    Start Command  kubectl exec ${kafkaPodName} -n ${NameSpace} -- bash -c "/opt/kafka/bin/kafka-topics.sh --list --zookeeper ${serviceName}:${servicePort}"
    ${output}=     Read Command Output    return_rc=True     return_stdout=True
    Should Be Equal As Integers    ${output}[1]    0
    Log    ${output}
    
68426_EDCA_DRD_Functional_TC_03 - Verify topic creation using DMaap endpoint
    [Documentation]    This testcase is to verify creation of new topic "pm-topic" using DMaap restendpoint
    ${requestBody}=    Create Dictionary   topicName=pm-topic    description=This is a test topic    partitionCount=1    replicationCount=3    transactionEnabled=true
    ${serviceName}=     Replace String    ${dmaapService}    service/    ${EMPTY}
    ${servicePort}=     Execute Command   kubectl get ${dmaapService} -o jsonpath='{.spec.ports[0].targetPort}' -n ${NameSpace}
    Start Command  kubectl exec -it ${kafkaPodName} -n ${NameSpace} -- curl -X POST http://${serviceName}.${NameSpace}:${servicePort}/topics/create -H 'Content-Type: application/json' -d "${requestBody}"
    ${output}=     Read Command Output    return_rc=True     return_stdout=True
    Should Be Equal As Integers    ${output[1]}    0
    Log    ${output[0]}
     
68426_EDCA_DRD_Functional_TC_04 - Verify topic creation in kafka
    [Documentation]    This testcase is to verify new topic creation in Kafka
    ${topicName}=    Generate Random String    6   [LOWER]
    ${serviceName}=     Replace String    ${zkServiceName}    service/    ${EMPTY}
    ${servicePort}=     Execute Command   kubectl get ${zkServiceName} -o jsonpath='{.spec.ports[?(@.name=="client")].targetPort}' -n ${NameSpace}
    Start Command  kubectl exec ${kafkaPodName} -n ${NameSpace} -- bash -c "/opt/kafka/bin/kafka-topics.sh --create --topic ${topicName} --replication-factor 3 --partitions 3 --zookeeper ${serviceName}:${servicePort}"
    ${writeOutput}=     Read Command Output    return_rc=False   return_stdout=True
    Should Be Equal    ${writeOutput}    Created topic "${topicName}".
    Start Command  kubectl exec ${kafkaPodName} -n ${NameSpace} -- bash -c "/opt/kafka/bin/kafka-topics.sh --list --zookeeper ${serviceName}:${servicePort} | grep ${topicName}"
    ${readOutput}=     Read Command Output    return_rc=False     return_stdout=True
    Should Be Equal    ${readOutput}    ${topicName}
    Log    ${writeOutput}
     
68426_EDCA_DRD_Functional_TC_05 - Verify Get specific topic details using DMaap endpoint
     [Documentation]    This test case is to verify created topic "pmtopic" from Dmaap using restendpoints
     ${topicName}=     Convert to String  pm-topic
     ${serviceName}=     Replace String    ${dmaapService}    service/    ${EMPTY}
     ${servicePort}=     Execute Command  kubectl get ${dmaapService} -o jsonpath='{.spec.ports[0].targetPort}' -n ${NameSpace}
     Start Command  kubectl exec ${kafkaPodName} -n ${NameSpace} -- bash -c "curl -X GET http://${serviceName}.${NameSpace}:${servicePort}/topics/${topicName}"
     ${outputCode}=     Read Command Output    return_rc=False     return_stdout=True
     ${jsonOutput}=    evaluate    json.loads('''${outputCode}''')    json
     Log    ${jsonOutput}
     Should be Equal    ${jsonOutput['name']}    ${topicName}
     
68426_EDCA_DRD_Functional_TC_06 - Verify publish messages to a topic
     [Documentation]    This testcase is to verify the process of publishing messages to a topic in Dmaap.
     ${requestBody}=    Create Dictionary   message=Test Message
     ${topicName}=     Convert to String  pm-topic
     ${serviceName}=     Replace String    ${dmaapService}    service/    ${EMPTY}
     ${servicePort}=     Execute Command  kubectl get ${dmaapService} -o jsonpath='{.spec.ports[0].targetPort}' -n ${NameSpace}
     Start Command  kubectl exec ${kafkaPodName} -n ${NameSpace} -- curl -X POST http://${serviceName}.${NameSpace}:${servicePort}/events/${topicName} -H 'Content-Type: application/json' -d "${requestBody}"
     ${outputCode}=     Read Command Output    return_rc=True     return_stdout=True
     Should be Equal As Integers    ${outputCode}[1]    0
     Log    ${outputCode}[0]
     
68426_EDCA_DRD_Functional_TC_07 - Verify subscribe to a topic
     [Documentation]    This testcase is to verify the process of subscribing messages from a topic in Dmaap.
     ${requestBody}=    Create Dictionary   message=Test Message
     ${topicName}=     Convert to String  pm-topic
     ${serviceName}=     Replace String    ${dmaapService}    service/    ${EMPTY}
     ${servicePort}=     Execute Command  kubectl get ${dmaapService} -o jsonpath='{.spec.ports[0].targetPort}' -n ${NameSpace}
     FOR    ${index}    IN RANGE    0    2
     Execute Command  kubectl exec ${kafkaPodName} -n ${NameSpace} -- curl -X POST http://${serviceName}.${NameSpace}:${servicePort}/events/${topicName} -H 'Content-Type: application/json' -d "${requestBody}" 
     ${outputCode}=    Execute Command  kubectl exec ${kafkaPodName} -n ${NameSpace} -- curl -X GET http://${serviceName}.${NameSpace}:${servicePort}/events/${topicName}/CG1/C1
     END
     Log    ${outputCode}
     ${outputMessage}=    Evaluate    json.loads(json.dumps(${outputCode}))    json
     Should be Equal    ${outputMessage[0]}    {"message":"Test Message"}
     Log    ${outputMessage}
     
68426_EDCA_DRD_Functional_TC_08 - Verify deletion of a topic
     [Documentation]    This testcase is to verify the deletion of topic from the Dmaap using restendpoints.
     #topic exists still after deletion.Issue raised with EO Team
     ${topicName}=     Convert to String  pm-topic
     ${serviceName}=     Replace String    ${dmaapService}    service/    ${EMPTY}
     ${servicePort}=     Execute Command  kubectl get ${dmaapService} -o jsonpath='{.spec.ports[0].targetPort}' -n ${NameSpace}
     Start Command  kubectl exec ${kafkaPodName} -n ${NameSpace} -- bash -c "curl -X DELETE http://${serviceName}.${NameSpace}:${servicePort}/topics/${topicName}"
     ${outputCode}=     Read Command Output    return_rc=False     return_stdout=True
     Should be Equal    ${outputCode}    Topic [${topicName}] deleted successfully

68426_EDCA_DRD_Functional_TC_09 - Verify events stored in kafka brokers
     [Documentation]    This testcase is to verify the events stored in the kafka brokers.
     Start Command  kubectl exec ${kafkaPodName} -n ${NameSpace} -- bash -c "ls /opt/kafka/data"
     ${output}=     Read Command Output    return_rc=True     return_stdout=True
     Should be Equal As Integers    ${output[1]}    0
     Log    ${output[0]}

68426_EDCA_DRD_Functional_TC_10 - Verify retention period of kafka brokers
     [Documentation]    This testcase is to verify the retention period of storing logs in kafka brokers.
     Start Command  kubectl exec ${kafkaPodName} -n ${NameSpace} -- bash -c "cat opt/kafka/config/server.properties | grep log.retention"
     ${outputCode}=     Read Command Output    return_rc=True     return_stdout=True
     Should be Equal As Integers    ${outputCode[1]}    0
     Log    ${outputCode[0]}
     
68426_EDCA_DRD_Negative_TC_03 - Verify create a topic with existing name
     [Documentation]    This testcase is to verify creation of new topic "cm-topic" using DMaap restendpoint
      #  "Expected Result is 409 but getting 204. Issue raised with EO team"
     ${requestBody}=    Create Dictionary   topicName=cm-topic    description=This is a test topic    partitionCount=1    replicationCount=3    transactionEnabled=true
     ${serviceName}=     Replace String    ${dmaapService}    service/    ${EMPTY}
     ${servicePort}=     Execute Command   kubectl get ${dmaapService} -o jsonpath='{.spec.ports[0].targetPort}' -n ${NameSpace}
     Start Command  kubectl exec ${kafkaPodName} -n ${NameSpace} -- curl -sSL -D - POST http://${serviceName}.${NameSpace}:${servicePort}/topics/create -H 'Content-Type: application/json' -d "${requestBody}" -o /dev/null | grep HTTP 
     ${output}=     Read Command Output    return_rc=True     return_stdout=True
     Should Contain    ${output[0]}    200
     Log    ${output[0]}
     
68426_EDCA_DRD_Negative_TC_01 - Deletion of pre-defined topic
     [Documentation]    This testcase is to verify the deletion of the created topic "cm-topic" using Dmaap endpoints.
     # ... topic exists even after deletion.Issue raised with EO Team
     ${topicName}=     Convert to String  cm-topic
     ${serviceName}=     Replace String    ${dmaapService}    service/    ${EMPTY}
     ${servicePort}=     Execute Command  kubectl get ${dmaapService} -o jsonpath='{.spec.ports[0].targetPort}' -n ${NameSpace}
     Start Command  kubectl exec ${kafkaPodName} -n ${NameSpace} -- bash -c "curl -X DELETE http://${serviceName}.${NameSpace}:${servicePort}/topics/${topicName}"
     ${outputCode}=     Read Command Output    return_rc=False     return_stdout=True
     Should be Equal    ${outputCode}    Topic [${topicName}] deleted successfully
     
68426_EDCA_DRD_Negative_TC_02 - verify Create a topic with wrong payload(content-type mismatch)
     [Documentation]    This testcase is to verify the topic Creation in dmaap using wrong payload
     ${requestBody}=    Create Dictionary   topicName=12345    description=This is a test topic    partitionCount=1    replicationCount=3    transactionEnabled=true
     ${serviceName}=     Replace String    ${dmaapService}    service/    ${EMPTY}
     ${servicePort}=     Execute Command  kubectl get ${dmaapService} -o jsonpath='{.spec.ports[0].targetPort}' -n ${NameSpace}
     Start Command  kubectl exec ${kafkaPodName} -n ${NameSpace} -- bash -c "curl -X POST http://${serviceName}.${NameSpace}:${servicePort}/topics/create -d ${requestBody}"
     ${output}=     Read Command Output    return_rc=True     return_stdout=True
     Should Be Equal As Integers    ${output[1]}    3
     Log    ${output[0]}
     
68426_EDCA_DRD_Negative_TC_04 - Verify Get topic with wrong details(non-existing topic)
     [Documentation]    This testcase is to verify the getting topic with wrong details in request
     ${topicName}=    Convert to String    notopic
     ${serviceName}=     Replace String    ${dmaapService}    service/    ${EMPTY}
     ${servicePort}=     Execute Command  kubectl get ${dmaapService} -o jsonpath='{.spec.ports[0].targetPort}' -n ${NameSpace}
     Start Command  kubectl exec ${kafkaPodName} -n ${NameSpace} -- bash -c "curl -X GET http://${serviceName}.${NameSpace}:${servicePort}/topics/${topicName}"
     ${output}=     Read Command Output    return_rc=True     return_stdout=True
     Should Be Equal As Integers    ${output[1]}    0
     ${statusCode}    Evaluate    json.loads(json.dumps(${output[0]}))    json
     Should Be Equal As Integers    ${statusCode['status']}    404
     Log    ${statusCode}
    
68426_EDCA_DRD_Negative_TC_05 - Verify subscribe to topic with wrong payload
     [Documentation]    This testcase is to verify the subscribing topic with wrong details(non-existing topic, non-existng consumer groups)
     ${topicName}=    Convert to String    notopic
     ${serviceName}=     Replace String    ${dmaapService}    service/    ${EMPTY}
     ${servicePort}=     Execute Command  kubectl get ${dmaapService} -o jsonpath='{.spec.ports[0].targetPort}' -n ${NameSpace}
     Start Command  kubectl exec ${kafkaPodName} -n ${NameSpace} -- bash -c "curl -X GET http://${serviceName}.${NameSpace}:${servicePort}/events/${topicName}/CG1/c1"
     ${output}=     Read Command Output    return_rc=True     return_stdout=True
     Should Be Equal As Integers    ${output[1]}    0
     ${statusCode}    Evaluate    json.loads(json.dumps(${output[0]}))    json
     Should Be Equal As Integers    ${statusCode['status']}    404
     Log    ${statusCode}

68426_EDCA_DRD_Negative_TC_06 - Verify delete topic with wrong details
     [Documentation]    This testcase is to verify the topic deletion operation with wrong details(topicName is invalid)
     ${topicName}=    Convert to String    notopic
     ${serviceName}=     Replace String    ${dmaapService}    service/    ${EMPTY}
     ${servicePort}=     Execute Command  kubectl get ${dmaapService} -o jsonpath='{.spec.ports[0].targetPort}' -n ${NameSpace}
     Start Command  kubectl exec ${kafkaPodName} -n ${NameSpace} -- bash -c "curl -X DELETE http://${serviceName}.${NameSpace}:${servicePort}/topics/${topicName}"
     ${output}=     Read Command Output    return_rc=True     return_stdout=True
     Should Be Equal As Integers    ${output[1]}    0
     ${statusCode}    Evaluate    json.loads(json.dumps(${output[0]}))    json
     Should Be Equal As Integers    ${statusCode['status']}    404
     Log    ${statusCode}
     Start Command  kubectl exec ${kafkaPodName} -n ${NameSpace} -- bash -c "curl -X DELETE http://${serviceName}.${NameSpace}:${servicePort}/topics"
     ${output}=     Read Command Output    return_rc=True     return_stdout=False
     Should Be Equal As Integers    ${output}    0