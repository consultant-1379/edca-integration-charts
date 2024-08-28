# EDCA Integration Chart
	EDCA Integration Chart is the consolidated piece of chart where all the services are embedded as sub charts for ease in Integration and deployment of services.
	Integration Chart ties together the sub-charts by expressing as dependencies using requirements.yaml file rather than explicitly exposing as separate charts and 
	it provides a possible way to override or set configuration parameters exposed by the separate sub-charts/services.
	
# Components/Services used in the Integration Chart

    Catalog Service
    DRD - DMaaP MR
    DRD - Kafka
    BDR - ADP Object Storage MN (MinIO)
    ADP PM Service
    ADP Logging Services

# EDCA Integration Helm Deployment

	helm install [NAME] [CHART] [flags]

	The install argument must be a chart reference, a path to a packaged chart or a URL.
	Eg: helm install eric-edca eric-edca-integration-helm-1.0.0-100.tgz -n test-edca


	helm upgrade [RELEASE] [CHART] [flags]

	This command upgrades a release to a new version of a chart and upgrade arguments must be a release and chart.
	The chart argument can be either a chart reference or a path to a chart directory or a fully qualified URL.
	The latest version will be specified --version' flag is set.
	Eg: helm upgrade eric-edca <chart-name> -n test-edca


	helm rollback <RELEASE> [REVISION] [flags]

	This command is used for rolls back a release to a previous revision.The first argument of the rollback command is the name of a release,
	and the second is a revision (version) number.If this argument is not mentioned then it will roll back to the previous release.
	Note: To see revision numbers, run helm history RELEASE
	Eg: helm rollback eric-edca <revision-num> -n test-edca