/**
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 */
const AWS = require('aws-sdk');


const sendEmail = async (email_to_adresses,email_cc_adresses,sender_email,state,video_name="",output_file="",supportEmail="exploitation-tech-digital@nextinteractive.fr") => {
    // Create sendEmail params
let successMessage = `<p>Bonjour,</p><p>Votre demande de watermarking kantar pour la créative <strong>${video_name}</strong> a <strong>réussie</strong> .</p><p>La créative marquée a pour chemin: <strong>${output_file}</strong></p>`
let errorMessage = `<p>Bonjour,</p><p>Votre demande de watermarking kantar pour la créative <strong>${video_name}</strong> a <strong>échouée</strong> .</p><p>N'hésitez pas à contacter <strong>${supportEmail}</strong> pour une assistance technique</p>`
let htmlMessage = state == "error" ? errorMessage : successMessage
var params = {
    Destination: {
      CcAddresses: email_cc_adresses,
      ToAddresses: email_to_adresses,
    },
    Message: {
      Body: { 
        Html: {
         Charset: "UTF-8",
         Data: htmlMessage
        }
       },
       Subject: {
        Charset: 'UTF-8',
        Data: 'Watermarking Kantar'
       }
      },
    Source: sender_email
  };
  
  // Create the promise and SES service object
  var sendPromise = new AWS.SES({region: 'eu-west-1'}).sendEmail(params).promise();
  console.log("READY to send");
  
  // Handle promise's fulfilled/rejected states
  try{
   await sendPromise
   console.log("sent successfully")
  }
  catch(err){
    console.log("Error in ses sending")
    console.log(err)
  }
  
}

/**
 * Download Job Manifest file from s3 and update the source file info
*/
const writeManifest = async (bucket, manifestFile,jobDetails) => {
    
    let results = {};
    try {
        const s3 = new AWS.S3();
        /**
         * Download the settings file for S3
         */
        let manifest = await s3.getObject({
            Bucket: bucket,
            Key: manifestFile
        }).promise();
        manifest = JSON.parse(manifest.Body);
 
        if (jobDetails.detail) {
            /**
             * event is a newly submited job to MediaConvert, creating a recored 
             * for the source file in the manifest file
             */
            console.log(`Writting input info for ${jobDetails.detail.jobId}`);
            manifest.Jobs.push({
                Id:jobDetails.detail.jobId,
                InputDetails: jobDetails.detail.inputDetails[0],
                InputFile: jobDetails.detail.inputDetails[0].uri
            });
        } else {
            /**
             * event is the processed outputs from a completed job in MediaConvert, 
             * updating the manifest file.
             */
             console.log(`Writting jobDetails for ${jobDetails.Id}`);
            const index = manifest.Jobs.findIndex(job => job.Id === jobDetails.Id);
            if (index === -1) {
                console.log(`no entry found for jobId: ${jobDetails.Id}, creating new entry`);
                jobDetails.InputDetails = {};
                manifest.Jobs.push(jobDetails);
                results = jobDetails;
            } else {
                results = {...manifest.Jobs[index], ...jobDetails};
                manifest.Jobs[index] = results;
            }
        }
        await s3.putObject({
            Bucket: bucket,
            Key: manifestFile,
            Body: JSON.stringify(manifest)
        }).promise();
    } catch (err) {
        throw {
            Message:'Failed to update the jobs-manifest.json, please check its accessible in the root of the source S3 bucket',
            Error: err,
            Job: jobDetails
        };
    }
    return results;
};


/**
 * Ge the Job details from MediaConvert and process the MediaConvert output details 
 * from Cloudwatch
*/
const processJobDetails = async (endpoint,data) => {
    console.log('Processing MediaConvert outputs');
    const mediaconvert = new AWS.MediaConvert({
        endpoint: endpoint,
        customUserAgent: process.env.SOLUTION_IDENTIFIER
    });
    let jobDetails = {};
    
    try {
        const jobData = await mediaconvert.getJob({ Id: data.detail.jobId }).promise();
        
        jobDetails = {
            Id:data.detail.jobId,
            Job:jobData.Job,
            OutputGroupDetails: data.detail.outputGroupDetails,
            Outputs: {
                HLS_GROUP:[],
                DASH_ISO_GROUP:[],
                CMAF_GROUP:[],
                MS_SMOOTH_GROUP:[],
                FILE_GROUP:[],
                THUMB_NAILS:[]
            }
        };
    /**
     * Cleanup any empty output groups
     */
    for (const output in jobDetails.Outputs) {
        if (jobDetails.Outputs[output] < 1) delete jobDetails.Outputs[output];
    }
    } catch (err) {
        console.error(err);
        throw err;
    }
     console.log(`JOB DETAILS:: ${JSON.stringify(jobDetails, null, 2)}`);
    return jobDetails;
};


/**
 * Send An sns notification for any failed jobs
 */
const sendSns = async (topic,status,data) => {
    const sns = new AWS.SNS({
        region: process.env.REGION
    });
    try {
        let id,msg;
        
        switch (status) {
            case 'COMPLETE':
                /**
                * reduce the data object just send Id,InputFile, Outputs
                */ 
                id = data.Id;
                msg = {
                    Id:data.Id,
                    InputFile: data.InputFile,
                    InputDetails: data.InputDetails,
                    Outputs: data.OutputGroupDetails[0].outputDetails.outputFilePaths[0]
                };
                break;
            case 'CANCELED':
            case 'ERROR':
                /**
                 * Adding CloudWatch log link for failed jobs
                 */
                id =  data.detail.jobId;
                msg = {
                    Details:`https://console.aws.amazon.com/mediaconvert/home?region=${process.env.AWS_REGION}#/jobs/summary/${id}`,
                    ErrorMsg: data
                };
                break;
            case 'PROCESSING ERROR':
                /**
                 * Edge case where processing the MediaConvert outputs fails.
                 */
                id = data.Job.detail.jobId || data.detail.jobId;
                msg = data;
                break;
        }
        console.log(`Sending ${status} SNS notification ${id}`);
        await sns.publish({
            TargetArn: topic,
            Message: JSON.stringify(msg, null, 2),
            Subject: `Job ${status} id:${id}`,
        }).promise();
    } catch (err) {
        console.error(err);
        throw err;
    }
};


module.exports = {
    writeManifest:writeManifest,
    processJobDetails:processJobDetails,
    sendSns:sendSns,
    sendEmail:sendEmail
};
