node {
    environment {
        APP_NAME = "SampleNodeJs"
        STAGING = "Staging"
        PRODUCTION = "Production"
    }
 
 	stage('cleanup') {
 		deleteDir()
 		//checkout scm
 	}
 
    stage('Checkout') {
        // Checkout our application source code
        git url: 'https://github.com/pcjeffmac/jenkins-dynatrace-pipeline-tutorial.git', credentialsId: '0ab85f6f2492796b11f0fdb1cded9efe37e0a68e', branch: 'master'
        // into a dynatrace-cli subdirectory we checkout the CLI
        dir ('dynatrace-cli') {
            git url: 'https://github.com/Dynatrace/dynatrace-cli.git', credentialsId: 'cd41a86f-ea57-4477-9b10-7f9277e650e1', branch: 'master'
        }
    }

    stage('Build') {
        // Lets build our docker image
        dir ('sample-nodejs-service') {
            def app = docker.build("sample-nodejs-service:${BUILD_NUMBER}")
        }
    }
    
    stage('CleanStaging') {
        // The cleanup script makes sure no previous docker staging containers run
        dir ('sample-nodejs-service') {
            sh "./cleanup.sh SampleNodeJsStaging"
        }
    }
    
    stage('DeployStaging') {
        // Lets deploy the previously build container
        def app = docker.image("sample-nodejs-service:${BUILD_NUMBER}")
        app.run("--name SampleNodeJsStaging -p 8480:80 " +
                "-e 'DT_CLUSTER_ID=SampleNodeJsStaging' " + 
                "-e 'DT_TAGS=Environment=Staging Service=Sample-NodeJs-Service' " +
                "-e 'DT_CUSTOM_PROP=ENVIRONMENT=Staging JOB_NAME=${JOB_NAME} " + 
                    "BUILD_TAG=${BUILD_TAG} BUILD_NUMBER=${BUIlD_NUMBER}'")

		echo "BUILD_NUMBER: ${BUILD_NUMBER}"
		
        dir ('dynatrace-scripts') {

        	//Dynatrace POST action for deployment Event      	
        	def body = """{"eventType": "CUSTOM_DEPLOYMENT",
  					"attachRules": {
    				"tagRule" : {
        			"meTypes" : "HOST",
        				"tags" : "Jenkins"
    					}
  					},
  					"deploymentName":"${JOB_NAME} - ${BUILD_NUMBER} Staging (http)",
  					"deploymentVersion":"1.1",
  					"deploymentProject":"DockerService",
  					"remediationAction":"https://ansible.pcjeffint.com/#/templates/job_template/7",
  					"ciBackLink":"${BUILD_URL}",
  					"source":"Jenkins",
  					"customProperties":{
    					"Jenkins Build Number": "${BUILD_ID}",
    					"Environment": "Staging",
    					"Job URL": "${JOB_URL}",
    					"Build URL": "${BUILD_URL}"
  						}
					}"""
        	
			httpRequest acceptType: 'APPLICATION_JSON', authentication: 'a47386bc-8488-41c0-a806-07b1123560e3', contentType: 'APPLICATION_JSON', customHeaders: [[maskValue: true, name: 'Authorization', value: 'Api-Token CGVha39QTheyn1UFufsvC']], httpMode: 'POST', ignoreSslErrors: true, requestBody: body, responseHandle: 'NONE', url: 'https://ibg73613.live.dynatrace.com/api/v1/events/'        	
            
            echo "Jenkins URL: ${JENKINS_URL}"
            echo "Job URL: ${JOB_URL}"
            echo "Build URL: ${BUILD_URL}" 
            
            // push a deployment event on the host with the tag [AWS]Environment:JenkinsTutorial
            sh './pushdeployment.sh HOST CONTEXTLESS jenkins jenkinsDynatrace ' +
               '${BUILD_TAG} ${BUILD_NUMBER} ${JOB_NAME} Jenkins ${JENKINS_URL} ${JOB_URL} ${BUILD_URL} None'
            
            // now I push one on the actual service (it has the tags from our rules)
            sh './pushdeployment.sh SERVICE CONTEXTLESS DockerService SampleNodeJsStaging ' + 
               '${BUILD_TAG} ${BUILD_NUMBER} ${JOB_NAME} ' + 
               'Jenkins ${JENKINS_URL} ${JOB_URL} ${BUILD_URL} ${GIT_COMMIT}'
        }    
    }
    
    stage('Testing') {
        // lets push an event to dynatrace that indicates that we START a load test
        dir ('dynatrace-scripts') {
            sh './pushevent.sh SERVICE CONTEXTLESS DockerService SampleNodeJsStaging ' +
               '"STARTING Load Test" ${JOB_NAME} "Starting a Load Test as part of the Testing stage"' + 
               ' ${JENKINS_URL} ${JOB_URL} ${BUILD_URL} ${GIT_COMMIT}'
        }
        
        // lets run some test scripts
        dir ('sample-nodejs-service-tests') {
            // start load test and run for 120 seconds - simulating traffic for Staging enviornment on port 80
            sh "rm -f stagingloadtest.log stagingloadtestcontrol.txt"
            sh "./loadtest.sh 8480 stagingloadtest.log stagingloadtestcontrol.txt 120 Staging"
            
            archiveArtifacts artifacts: 'stagingloadtest.log', fingerprint: true
        }

        // lets push an event to dynatrace that indicates that we STOP a load test
        dir ('dynatrace-scripts') {
            sh './pushevent.sh SERVICE CONTEXTLESS DockerService SampleNodeJsStaging '+
               '"STOPPING Load Test" ${JOB_NAME} "Stopping a Load Test as part of the Testing stage" '+
               '${JENKINS_URL} ${JOB_URL} ${BUILD_URL} ${GIT_COMMIT}'
        }
    }
    
    stage('ValidateStaging') {
        // lets see if Dynatrace AI found problems -> if so - we can stop the pipeline!
        dir ('dynatrace-scripts') {
            DYNATRACE_PROBLEM_COUNT = sh (script: './checkforproblems.sh', returnStatus : true)
            echo "Dynatrace Problems Found: ${DYNATRACE_PROBLEM_COUNT}"
        }
        
        // now lets generate a report using our CLI and lets generate some direct links back to dynatrace
        dir ('dynatrace-cli') {
            sh 'python3 dtcli.py dqlr srv tags/CONTEXTLESS:DockerService=SampleNodeJsStaging '+
                        'service.responsetime[avg%hour],service.responsetime[p90%hour] ${DT_URL} ${DT_TOKEN}'
            sh 'mv dqlreport.html dqlstagingreport.html'
            archiveArtifacts artifacts: 'dqlstagingreport.html', fingerprint: true
            
            // get the link to the service's dashboard and make it an artifact
            sh 'python3 dtcli.py link srv tags/CONTEXTLESS:DockerService=SampleNodeJsStaging '+
                        'overview 60:0 ${DT_URL} ${DT_TOKEN} > dtstagelinks.txt'
            archiveArtifacts artifacts: 'dtstagelinks.txt', fingerprint: true
        }
    }
    
    stage('DeployProduction') {
        // first we clean production
        dir ('sample-nodejs-service') {
            sh "./cleanup.sh SampleNodeJsProduction"
        }

        // now we deploy the new container
        def app = docker.image("sample-nodejs-service:${BUILD_NUMBER}")
        app.run("--name SampleNodeJsProduction -p 90:80 "+
                "-e 'DT_CLUSTER_ID=SampleNodeJsProduction' "+
                "-e 'DT_TAGS=Environment=Production Service=Sample-NodeJs-Service' "+
                "-e 'DT_CUSTOM_PROP=ENVIRONMENT=Production JOB_NAME=${JOB_NAME} "+
                    "BUILD_TAG=${BUILD_TAG} BUILD_NUMBER=${BUIlD_NUMBER}'")

		echo "BUILD_NUMBER - ${BUILD_NUMBER}"

        dir ('dynatrace-scripts') {
        
        	//Dynatrace POST action for deployment Event      	
        	def body = """{"eventType": "CUSTOM_DEPLOYMENT",
  					"attachRules": {
    				"tagRule" : {
        			"meTypes" : "HOST",
        				"tags" : "Jenkins"
    					}
  					},
  					"deploymentName":"${JOB_NAME} - ${BUILD_NUMBER} Production (http)",
  					"deploymentVersion":"1.1",
  					"deploymentProject":"DockerService",
  					"remediationAction":"https://ansible.pcjeffint.com/#/templates/job_template/7",
  					"ciBackLink":"${BUILD_URL}",
  					"source":"Jenkins",
  					"customProperties":{
    					"Jenkins Build Number": "${BUILD_ID}",
    					"Environment": "Production"
  						}
					}"""
        	
			httpRequest acceptType: 'APPLICATION_JSON', authentication: 'a47386bc-8488-41c0-a806-07b1123560e3', contentType: 'APPLICATION_JSON', customHeaders: [[maskValue: true, name: 'Authorization', value: 'Api-Token CGVha39QTheyn1UFufsvC']], httpMode: 'POST', ignoreSslErrors: true, requestBody: body, responseHandle: 'NONE', url: 'https://ibg73613.live.dynatrace.com/api/v1/events/'        	
                     
            // push a deployment event on the host with the tag [AWS]Environment:JenkinsTutorial
            sh './pushdeployment.sh HOST CONTEXTLESS jenkins jenkinsDynatrace '+
               '${BUILD_TAG} ${BUILD_NUMBER} ${JOB_NAME} Jenkins '+
               '${JENKINS_URL} ${JOB_URL} ${BUILD_URL} ${GIT_COMMIT}'
            
            // now I push one on the actual service (it has the tags from our rules)
            sh './pushdeployment.sh SERVICE CONTEXTLESS DockerService SampleNodeJsProduction '+
               '${BUILD_TAG} ${BUILD_NUMBER} ${JOB_NAME} Jenkins '+
               '${JENKINS_URL} ${JOB_URL} ${BUILD_URL} ${GIT_COMMIT}'
        }    
    }    
    
    stage('WarmUpProduction') {
        // lets push an event to dynatrace that indicates that we START a load test
        dir ('dynatrace-scripts') {
            sh './pushevent.sh SERVICE CONTEXTLESS DockerService SampleNodeJsProduction '+
               '"STARTING Load Test" ${JOB_NAME} "Starting a Load Test to warm up new prod deployment" '+
               '${JENKINS_URL} ${JOB_URL} ${BUILD_URL} ${GIT_COMMIT}'
        }
        
        // lets run some test scripts
        dir ('sample-nodejs-service-tests') {
            // start load test and run for 120 seconds - simulating traffic for Production enviornment on port 90
            sh "rm -f productionloadtest.log productionloadtestcontrol.txt"
            sh "./loadtest.sh 90 productionloadtest.log productionloadtestcontrol.txt 60 Production"
            
            archiveArtifacts artifacts: 'productionloadtest.log', fingerprint: true
        }

        // lets push an event to dynatrace that indicates that we STOP a load test
        dir ('dynatrace-scripts') {
            sh './pushevent.sh SERVICE CONTEXTLESS DockerService SampleNodeJsProduction '+
               '"STOPPING Load Test" ${JOB_NAME} "Stopping a Load Test as part of the Production warm up phase" '+
               '${JENKINS_URL} ${JOB_URL} ${BUILD_URL} ${GIT_COMMIT}'
        }
    }

   stage('Run NeoLoad - scenario1') {
        dir ('NeoLoad') {
        //NeoLoad Test
        neoloadRun executable: '/opt/Neoload6.7/bin/NeoLoadCmd', project: '/home/dynatrace/NeoLoadProjects/DemoProject/DemoProject.nlp', testName: 'scenerio1 $Date{hh:mm - dd MMM yyyy} (build ${BUILD_NUMBER})', testDescription: 'From Jenkins', commandLineOption: '-nlweb -nlwebAPIURL http://neoload.pcjeffint.com:8080/ -nlwebToken LQbc0Z2Rd1ObANsF9eUrlEaP', scenario: 'scenario1', trendGraphs: ['AvgResponseTime', 'ErrorRate']     
        }
    } 
       
    stage('ValidateProduction') {
        dir ('dynatrace-scripts') {
            DYNATRACE_PROBLEM_COUNT = sh (script: './checkforproblems.sh', returnStatus : true)
            echo "Dynatrace Problems Found: ${DYNATRACE_PROBLEM_COUNT}"
        }
   
        //perfSigDynatraceReports envId: 'DTSaaS', metrics: [[metricId: 'com.dynatrace.builtin:service.responsetime'], [metricId: 'com.dynatrace.builtin:pgi.cpu.usage']], nonFunctionalFailure: 2, specFile: '/home/dynatrace/monspec/monspec.json'
   
        // now lets generate a report using our CLI and lets generate some direct links back to dynatrace
        dir ('dynatrace-cli') {
            sh 'python3 dtcli.py dqlr srv tags/CONTEXTLESS:DockerService=SampleNodeJsProduction '+
               'service.responsetime[avg%hour],service.responsetime[p90%hour] ${DT_URL} ${DT_TOKEN}'
            sh 'mv dqlreport.html dqlproductionreport.html'
            archiveArtifacts artifacts: 'dqlproductionreport.html', fingerprint: true

            sh 'python3 dtcli.py link srv tags/CONTEXTLESS:DockerService=SampleNodeJsProduction ' +
            	' overview 60:0 ${DT_URL} ${DT_TOKEN} > dtprodlinks.txt'
            archiveArtifacts artifacts: 'dtprodlinks.txt', fingerprint: true
        }
    }  
     
}