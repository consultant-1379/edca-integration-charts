#!/bin/sh
namespace=${1}
# Configure minio host to the chart
POD_NAME=`kubectl get pod -l app=eric-data-object-storage-mn-mgt,role=management -n ${namespace}  -o jsonpath='{.items[0].metadata.name}'`
echo ${POD_NAME}

hostName=osmn
MINIO_ACCESS_KEY=`kubectl exec ${POD_NAME} -n ${namespace} -- bash -c 'echo $MINIO_ACCESS_KEY'`
MINIO_SECRET_KEY=`kubectl exec ${POD_NAME} -n ${namespace} -- bash -c 'echo $MINIO_SECRET_KEY'`
result=`kubectl exec ${POD_NAME} -n ${namespace} -- bash -c "mc config host add ${hostName} http://eric-data-object-storage-mn:9000 ${MINIO_ACCESS_KEY} ${MINIO_SECRET_KEY}"`
echo ${result}

#  Adding Pre-defined Buckets for Data Collection
bucketList=("mixed-data" "pm-data")

for bucketName in ${bucketList[*]}
do
kubectl exec ${POD_NAME} -n ${namespace} -- bash -c "mc mb ${hostName}/${bucketName}"
done

# Adding Pre-defined Users for Data Collection
USER_LIST=("ccuser" "drguser")
for  user in ${USER_LIST[*]}
do
CommandStatus=`kubectl exec ${POD_NAME} -n ${namespace} -- bash -c "mc admin user add ${hostName} ${user} ${user}123"`
echo  ${CommandStatus}
done

# Adding read & write user policies to bdr
cat > writeuserpolicy.json << EOF
{"Version":"2012-10-17","Statement":[{"Sid":"writeUserPolicy","Effect":"Allow","Action":["s3:PutObject","s3:ListBucket"],"Resource":["arn:aws:s3:::*"]}]}
EOF

cat > readuserpolicy.json  << EOF
{"Version":"2012-10-17","Statement":[{"Sid":"downloadpolicy","Effect":"Allow","Action":["s3:ListBucket","s3:GetObject","s3:GetBucketLocation","s3:GetBucketPolicy","s3:ListAllMyBuckets"],"Resource":["arn:aws:s3:::*"]}]}
EOF

PolicyList=("writeuserpolicy" "readuserpolicy")
kubectl cp readuserpolicy.json ${namespace}/${POD_NAME}:/minio
kubectl cp writeuserpolicy.json ${namespace}/${POD_NAME}:/minio

for policy in ${PolicyList[*]}
do
CommandStatus=`kubectl exec ${POD_NAME} -n ${namespace} -- bash -c "mc admin policy add ${hostName} ${policy} /minio/${policy}.json"`
echo  ${CommandStatus}
done

#  Assigning read & write user policies to pre-defined users
for element in 0 1
do
CommandStatus=`kubectl exec ${POD_NAME} -n ${namespace} -- bash -c "mc admin policy set ${hostName} ${PolicyList[${element}]} user=${USER_LIST[${element}]}"`
echo  ${CommandStatus}
done