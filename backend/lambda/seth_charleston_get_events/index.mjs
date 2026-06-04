import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { ScanCommand, DynamoDBDocumentClient } from "@aws-sdk/lib-dynamodb";
import crypto from "crypto";

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

export const handler = async (event, context) => {
  console.log("EVENT: \n" + JSON.stringify(event, null, 2));

  const command = new ScanCommand({
    TableName: 'seth_charleston_events'
  });

  const response = await docClient.send(command);
  console.log(response);

  return response;
};
