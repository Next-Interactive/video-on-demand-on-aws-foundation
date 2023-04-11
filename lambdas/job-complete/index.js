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
    let MEDIACONVERT_ENDPOINT = await getEndpoint();
    const {
        SNS_TOPIC_ARN,
        SOURCE_BUCKET,
        JOB_MANIFEST
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
                     * send a summary of the job to sns
                    */
                   console.log(results)
                   let inputFile = String(results.InputFile).split('/').slice(-1)[0];
                   let outputFile = String(results.OutputGroupDetails[0].outputDetails[0].outputFilePaths[0]).split('/').slice(3).join('/');
                    //await utils.sendSns(SNS_TOPIC_ARN,status,results);
                    console.log(inputFile,outputFile);
                    console.log("sending SES EMAIL")
                    await utils.sendEmail(["hicham.abid.prestataire@alticemedia.com"],["hicham.abid.prestataire@alticemedia.com"],"hicham.abid.prestataire@alticemedia.com","success",inputFile,outputFile);
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
                    await utils.sendEmail(["hicham.abid.prestataire@alticemedia.com"],["hicham.abid.prestataire@alticemedia.com"],"hicham.abid.prestataire@alticemedia.com","error");
                } catch (err) {
                    throw err;
                }
                break;
            default:
                throw new Error('Unknow job status');
        }
    } catch (err) {
        await utils.sendEmail(["hicham.abid.prestataire@alticemedia.com"],["hicham.abid.prestataire@alticemedia.com"],"hicham.abid.prestataire@alticemedia.com","error");
        console.log(err)
        throw err;
    }
    return;
};
