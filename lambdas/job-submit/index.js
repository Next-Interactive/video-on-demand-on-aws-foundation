/**
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 */
const uuidv4 = require('uuid/v4');
const utils = require('./lib/utils.js');
const options = { customUserAgent: process.env.SOLUTION_IDENTIFIER };
const AWS = require('aws-sdk');

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
        SNS_TOPIC_ARN
    } = process.env;
    
    try {
        /**
         * define inputs/ouputs and a unique string for the mediaconver output path in S3. 
         */
        console.log(event);
        const srcVideo = decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, " "));
        const srcBucket = decodeURIComponent(event.Records[0].s3.bucket.name);
        const settingsFile = `${srcVideo.split("/")[0]}/${JOB_SETTINGS}`;
        const guid = uuidv4();
        const inputPath = `s3://${srcBucket}/${srcVideo}`;
        const outputPath = `s3://${DESTINATION_BUCKET}/${guid}`;
        const kantarLogsPath = `s3://${KANTAR_LOGS_BUCKET}/kantar-logs/`;
        const metaData = {
            Guid:guid,
            SolutionId:SOLUTION_ID
        };
        /**
         * extract pubid from file name.
         */
        const pubidWithFileExtension = srcVideo.replace(/^.*_pubid_/, "");
        const pubid = pubidWithFileExtension.replace(/\.(mp4|mxf)$/i, "");
        console.log(pubid);
        /**
         * download and validate settings 
         */
        let job = await utils.getJobSettings(srcBucket,settingsFile);
        /**
         * parse settings file to update source / destination
         */
        job = await utils.updateJobSettings(job,inputPath,outputPath,metaData,MEDIACONVERT_ROLE,pubid,kantarLogsPath);
        /**
         * Submit Job
         */
        await utils.createJob(job,MEDIACONVERT_ENDPOINT);

    } catch (err) {
        /**
         * Send SNS error message
         */
        await utils.sendError(SNS_TOPIC_ARN,context.logGroupName,err);
        throw err;
    }
    return;
};
