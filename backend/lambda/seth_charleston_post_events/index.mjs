import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { PutCommand, DynamoDBDocumentClient } from "@aws-sdk/lib-dynamodb";
import crypto from "crypto";

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

export const handler = async (event, context) => {
  console.log("EVENT: \n" + JSON.stringify(event, null, 2));

  function createHash(inputString) {
    const hash = crypto.createHash('sha256');
    hash.update(inputString);
    return hash.digest('hex');
  }

  let command;
  if (event && event.event) {
    command = new PutCommand({
      TableName: "seth_charleston_events",
      Item: {
        event: event.event,
        name: event.name,
        when: event.when,
        where: event.where,
        tickets: event.tickets
      },
    });
  } else {
    command = new PutCommand({
      TableName: "seth_charleston_events",
      Item: {
        event: createHash(event.name),
        name: event.name,
        when: event.when,
        where: event.where,
        tickets: event.tickets
      },
    });
  }

  const response = await docClient.send(command);
  console.log(response);

  return context.logStreamName;
};
