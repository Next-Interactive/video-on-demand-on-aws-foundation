/**
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 */

const utils = require('./lib/utils.js');
const options = { customUserAgent: process.env.SOLUTION_IDENTIFIER };
const AWS = require('aws-sdk');
const uuidv4 = AWS.util.uuid.v4;

const getEndpoint = async () => {
    let endpoint;
    try {
        const mediaconvert = new AWS.MediaConvert(options);
        const data = await mediaconvert.describeEndpoints().promise();
        endpoint = data.Endpoints[0].Url;
    } catch (err) {
        console.error(err);
        throw err;
    }
    return endpoint;
};

exports.handler = async (event,context) => {
    console.log(context.LogGroupName);
    console.log(`REQUEST:: ${JSON.stringify(event, null, 2)}`);
    MEDIACONVERT_ENDPOINT = await getEndpoint();
    const {
        MEDIACONVERT_ROLE,
        JOB_SETTINGS,
        DESTINATION_BUCKET,
        KANTAR_LOGS_BUCKET,
        SOLUTION_ID,
        SUPPORT_EMAIL,
        RAW_VIDEO_FOLDER,
        MARKED_VIDEO_FOLDER,
        KANTAR_LOG_FOLDER
    } = process.env;
    
    try {
        /**
         * define inputs/ouputs and a unique string for the mediaconver output path in S3. 
         */
        console.log(event);
        const today = new Date();
        const day = today.getDate().toString().padStart(2, '0');
        const month = (today.getMonth() + 1).toString().padStart(2, '0');
        const year = today.getFullYear().toString();


        const srcVideo = decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, " "));
        const srcBucket = decodeURIComponent(event.Records[0].s3.bucket.name);
        const settingsFile = `${RAW_VIDEO_FOLDER}/${JOB_SETTINGS}`;
        const guid = uuidv4();
        const inputPath = `s3://${srcBucket}/${srcVideo}`;

         /**
         * extract pubid from file name.
         */
         const pubidWithFileExtension = srcVideo.replace(/^.*_pubid_/, "");
         const pubid = pubidWithFileExtension.replace(/\.(mp4|mxf)$/i, "");
         console.log("PUBID",pubid);


        const outputPath = `s3://${DESTINATION_BUCKET}/${MARKED_VIDEO_FOLDER}/${year}/${month}/${day}`;
        const kantarLogsPath = `s3://${KANTAR_LOGS_BUCKET}/${KANTAR_LOG_FOLDER}/${year}/${month}/${day}/`;
        const metaData = {
            Guid:guid,
            SolutionId:SOLUTION_ID
        };
        
        
        
        /**
         * download and validate settings 
         */
        let job = await utils.getJobSettings(srcBucket,settingsFile);
        console.log(job)
        /**
         * parse settings file to update source / destination
         */
        job = await utils.updateJobSettings(job,inputPath,outputPath,metaData,MEDIACONVERT_ROLE,pubid,kantarLogsPath);
        console.log(job)
        /**
         * Submit Job
         */
        console.log("TRYING CREATE JOB")
        await utils.createJob(job,MEDIACONVERT_ENDPOINT);

    } catch (err) {
        await utils.sendEmail([SUPPORT_EMAIL],SUPPORT_EMAIL);
        throw err;
    }
    return;
};
