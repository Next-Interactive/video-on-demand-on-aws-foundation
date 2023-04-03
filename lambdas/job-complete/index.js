/**
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: Apache-2.0
 */
const options = { customUserAgent: process.env.SOLUTION_IDENTIFIER };
const AWS = require('aws-sdk');
const utils = require('./lib/utils.js');
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

exports.handler = async (event) => {
    console.log(`REQUEST:: ${JSON.stringify(event, null, 2)}`);
    MEDIACONVERT_ENDPOINT = await getEndpoint();
    const {
        SNS_TOPIC_ARN,
        SOURCE_BUCKET,
        JOB_MANIFEST,
        METRICS,
        SOLUTION_ID,
        VERSION,
        UUID
    } = process.env;

    try {
        const status = event.detail.status;

        switch (status) {
            case 'INPUT_INFORMATION':
                /**
                 * Write source info to the job manifest
                 */
                try {
                    await utils.writeManifest(SOURCE_BUCKET,JOB_MANIFEST,event);
                } catch (err) {
                    throw err;
                }
                break;
            case 'COMPLETE':
                try {
                    /**
                     * get the mediaconvert job details and parse the event outputs
                     */
                    const jobDetails = await utils.processJobDetails(MEDIACONVERT_ENDPOINT,event);
                    /**
                     * update the master manifest file in s3
                     */
                    const results = await utils.writeManifest(SOURCE_BUCKET,JOB_MANIFEST,jobDetails);
                    /**
                     * if enabled send annoymous data to the solution builder api, this helps us with future release
                     */
                    if (METRICS === 'Yes') {
                        await utils.sendMetrics(SOLUTION_ID,VERSION,UUID,results); 
                    }
                    /**
                     * send a summary of the job to sns
                    */
                    await utils.sendSns(SNS_TOPIC_ARN,status,results);
                } catch (err) {
                    throw err;
                }
                break;
            case 'CANCELED':
            case 'ERROR':
                /**
                 * Send error to SNS
                 */
                try {
                    await utils.sendSns(SNS_TOPIC_ARN,status,event);
                } catch (err) {
                    throw err;
                }
                break;
            default:
                throw new Error('Unknow job status');
        }
    } catch (err) {
        await utils.sendSns(SNS_TOPIC_ARN,'PROCESSING ERROR',err);
        throw err;
    }
    return;
};