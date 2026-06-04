import { CloudFrontClient, CreateInvalidationCommand } from "@aws-sdk/client-cloudfront";
import { CodePipelineClient, PutJobSuccessResultCommand, PutJobFailureResultCommand } from "@aws-sdk/client-codepipeline";

export const handler = async (event, context) => {
  var putJobSuccess = async function() {
    console.log('Notifying CodePipeline of a successful job');
    const client = new CodePipelineClient();
    const input = {
      jobId: event["CodePipeline.job"].id
    };
    const command = new PutJobSuccessResultCommand(input);
    const response = await client.send(command);
    console.log(response);
  };

  var putJobFailure = async function(message) {
    console.log('Notifying CodePipeline of a failed job');
    const client = new CodePipelineClient();
    const input = {
      jobId: event["CodePipeline.job"].id,
      failureDetails: {
        type: "JobFailed",
        message: message
      }
    };
    const command = new PutJobFailureResultCommand(input);
    const response = await client.send(command);
    console.log(response);
  };

  console.log(event["CodePipeline.job"].data.actionConfiguration.configuration.UserParameters);
  const client = new CloudFrontClient();
  const input = {
    DistributionId: event["CodePipeline.job"].data.actionConfiguration.configuration.UserParameters,
    InvalidationBatch: {
      Paths: {
        Quantity: 1,
        Items: [
          "/*",
        ],
      },
      CallerReference: Date.now().toString(),
    },
  };

  try {
    const command = new CreateInvalidationCommand(input);
    const response = await client.send(command);
    console.log(response);
    await putJobSuccess();
    return response;
  } catch (error) {
    await putJobFailure(error.message);
    console.log(error);
    return error.message;
  }
};
