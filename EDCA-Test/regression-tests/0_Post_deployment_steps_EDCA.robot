*** Settings ***
Library    SSHLibrary
Library    OperatingSystem
Library    String
Suite Setup    Open Connection and Log in
Suite Teardown    Close All Connections

*** Variables ***
${HOST}
${USERNAME}
${PASSWORD}
${NameSpace}

*** Keywords ***
Open Connection and Log in
    Open Connection    ${HOST}
    Login    ${USERNAME}    ${PASSWORD}

*** Test Cases ***
Getting BDR Pod Name
    [Documentation]    this step to get the bdr podname which will be used in the entire chart
    ${bdrPodName}=    Execute Command    kubectl get pod -o=name -n ${NameSpace} | grep eric-data-object-storage-mn-mgt
    Set Global Variable    ${bdrPodName}
    ${hostName}=    Convert to String    osmn
    Set Global Variable    ${hostName}

Step1 - Configure minio host to the chart
    [Documentation]    This step is to configure the management pod to connect to Object storage mn service
    ${hostAlias}=    Convert to String    http://eric-data-object-storage-mn:9000
    ${accesskey}=    Execute Command    kubectl exec ${bdrPodName} -n ${NameSpace} -c manager -- sh -c 'echo $MINIO_ACCESS_KEY'
    ${secretkey}=    Execute Command    kubectl exec ${bdrPodName} -n ${NameSpace} -c manager -- sh -c 'echo $MINIO_SECRET_KEY'
    ${CommandStatus}=    Execute Command    kubectl exec ${bdrPodName} -n ${NameSpace} -c manager -- bash -c "mc config host add ${hostName} ${hostAlias} ${accesskey} ${secretkey}"
    Should Contain    ${CommandStatus}    Added `${hostName}` successfully

Step2 - Adding Pre-defined Buckets for Data Collection
    [Documentation]    This step is to add the predefined buckets in the bdr for data collection
    @{BucketList}=    Create List    mixed-data    pm-data
    FOR    ${bucketName}    IN    @{BucketList}
        ${CommandStatus}=          Execute Command     kubectl exec ${bdrPodName} -n ${NameSpace} -c manager -- sh -c "mc mb ${hostName}/${bucketName}"
        Should Contain    ${CommandStatus}    Bucket created successfully `${hostName}/${bucketName}`
    END

Step3 - Adding Pre-defined Users for Data Collection
    [Documentation]    This step is to add the predefined users in the bdr for data collection by the simulators
    @{UsersList}=    Create List    ccuser    drguser
    FOR    ${user}    IN    @{UsersList}
        ${CommandStatus}=          Execute Command     kubectl exec ${bdrPodName} -n ${NameSpace} -c manager -- bash -c "mc admin user add ${hostName} ${user} ${user}123"
        Should Contain    ${CommandStatus}    Added user `${user}` successfully
    END

Step4 - Adding read & write user policies to bdr
    [Documentation]    This step is to add the read & write user policies to the bdr
    @{PolicyList}    Create List    writeuserpolicy    readuserpolicy
    Create File    writeuserpolicy.json    {"Version":"2012-10-17","Statement":[{"Sid":"writeUserPolicy","Effect":"Allow","Action":["s3:PutObject","s3:ListBucket"],"Resource":["arn:aws:s3:::*"]}]}
    Create File    readuserpolicy.json    {"Version":"2012-10-17","Statement":[{"Sid":"downloadpolicy","Effect":"Allow","Action":["s3:ListBucket","s3:GetObject","s3:GetBucketLocation","s3:GetBucketPolicy","s3:ListAllMyBuckets"],"Resource":["arn:aws:s3:::*"]}]}
    Put File    readuserpolicy.json
    Put File    writeuserpolicy.json
    ${podName}=    Replace String    ${bdrPodName}    pod/    ${EMPTY}
    Execute Command    kubectl cp /root/readuserpolicy.json ${NameSpace}/${podName}:/minio -c manager
    Execute Command    kubectl cp /root/writeuserpolicy.json ${NameSpace}/${podName}:/minio -c manager
    Execute Command    rm -f readuserpolicy.json && rm -f writeuserpolicy.json
    Remove File    readuserpolicy.json
    Remove File    writeuserpolicy.json
    FOR    ${policy}    IN    @{PolicyList}
        ${CommandStatus}=          Execute Command     kubectl exec ${bdrPodName} -n ${NameSpace} -c manager -- bash -c "mc admin policy add osmn ${policy} /minio/${policy}.json"
        Should Contain    ${CommandStatus}    Added policy `${policy}` successfully
    END

Step5 - Assigning read & write user policies to pre-defined users
    [Documentation]    This step is to assign policies to users available in bdr
    @{PolicyList}    Create List    writeuserpolicy    readuserpolicy
    @{UsersList}=    Create List    ccuser    drguser
    FOR    ${element}    IN RANGE    0    2
        ${CommandStatus}=          Execute Command     kubectl exec ${bdrPodName} -n ${NameSpace} -c manager -- bash -c "mc admin policy set osmn ${PolicyList}[${element}] user=${UsersList}[${element}]"
        Should Contain    ${CommandStatus}    Policy `${PolicyList}[${element}]` is set on user `${UsersList}[${element}]`
    END