# COPYRIGHT Ericsson 2021
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.

import yaml
import sys
import os
try:
    if len(sys.argv) == 2 or len(sys.argv) == 3:
        file_name=sys.argv[1]
    else :
        file_name = "input.yaml"
    a_yaml_file = open(file_name)

    yaml_parse = yaml.load(a_yaml_file, Loader=yaml.FullLoader)

    # print(yaml_parse)
    text ="""
*** Settings ***
Resource         kubernetes_keyword.robot


*** Test Case ***
"""
    for kubernetes in yaml_parse['kubernetes'].get('namespace'):
        namespace = kubernetes.get("name")
        # print(namespace)
        for services in kubernetes.get("services"):
            # testcase="\nService"+str(i)+"\n"
            # testcase+="\tList services by label  "+namespace+"   app.kubernetes.io/name="+services
            testcase="\n"+services.get("testcase")+"\n"
            testcase+="\tList services by label  "+namespace+"   app.kubernetes.io/name="+services.get("service")
            text+=testcase
        for pod in kubernetes.get("pods"):
            testcase="\n"+pod.get("testcase")
            testcase+="\n\tTest Pod Status   "+namespace+"  "+pod.get("name")+"  "+str(pod.get("replica-count"))
            text+=testcase
        for cronjob in kubernetes.get("cronjobs"):
            testcase="\n"+cronjob.get("testcase")
            testcase+="\n\tList cron jobs with label   "+namespace+"   app.kubernetes.io/name="+cronjob.get("cronjob")
            text+=testcase
        for job in kubernetes.get("jobs"):
            testcase="\n"+job.get("testcase")
            testcase+="\n\tList jobs with label   .*   "+namespace+"   app.kubernetes.io/name="+job.get("job")
            text+=testcase
        for deployment in kubernetes.get("deployments"):
            testcase="\n"+deployment.get("testcase")
            testcase+="\n\tList all deployments in namespace  "+namespace+"  app.kubernetes.io/name="+deployment.get("name")+"  "+str(deployment.get("replicas"))
            text+=testcase

    if len(sys.argv) == 3:
        file_name=sys.argv[2]
        if os.path.exists(os.path.dirname(file_name)) == False:
            os.mkdir(os.path.dirname(file_name))
            print(os.path.dirname(file_name)+" is created")
    else:
        file_name="rest-api-testcases.robot"
    robot_gen_file=open(file_name,"w")
    robot_gen_file.write(text)

    robot_gen_file.close()
    a_yaml_file.close()
except Exception as ex:
    print(ex)
else:
    print("Robot test file generated successfully")
