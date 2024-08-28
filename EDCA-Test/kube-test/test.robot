
*** Settings ***
Resource         kubernetes_keyword.robot


*** Test Case ***

EDCA Integration Test Case to check eric-oss-dmaap service
	List services by label  edca-drop1   app.kubernetes.io/name=eric-oss-dmaap
EDCA Integration Test Case to check eric-log-transformer
	List services by label  edca-drop1   app.kubernetes.io/name=eric-log-transformer
EDCA Integration Test Case to check pod eric-oss-dmaap-kafka pod with replic
	Test Pod Status   edca-drop1  eric-oss-dmaap-kafka  3
EDCA Integration Test Case to check pod eric-oss-dmaap-0 pod with replic
	Test Pod Status   edca-drop1  eric-oss-dmaap-0  1
EDCA Integration Test Case to check cronjob eric-data-search-engine-curator
	List cron jobs with label   edca-drop1   app.kubernetes.io/name=eric-data-search-engine-curator
EDCA Integration Test Case to check job eric-data-search-engine-curator
	List jobs with label   .*   edca-drop1   app.kubernetes.io/name=eric-data-search-engine-curator
EDCA Integration Test Case to check job eric-data-search-engine-curator
	List jobs with label   .*   edca-drop1   app.kubernetes.io/name=eric-edca-integration-helm
EDCA Integration Test Case to check deployment eric-data-search-engine
	List all deployments in namespace  edca-drop1  app.kubernetes.io/name=eric-data-search-engine  1
EDCA Integration Test Case to check deployment eric-data-object-storage-mn
	List all deployments in namespace  edca-drop1  app.kubernetes.io/name=eric-data-object-storage-mn  1
EDCA Integration Test Case to check deployment eric-edca-catalog
	List all deployments in namespace  edca-drop1  app.kubernetes.io/name=eric-edca-catalog  2