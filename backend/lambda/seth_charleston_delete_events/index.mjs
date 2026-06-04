import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DeleteCommand, DynamoDBDocumentClient } from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

export const handler = async (event, context) => {
  console.log("EVENT: \n" + JSON.stringify(event, null, 2));

  const command = new DeleteCommand({
    TableName: "seth_charleston_events",
    Key: { event: event.event },
  });

  const response = await docClient.send(command);
  console.log(response);

  return context.logStreamName;
};
