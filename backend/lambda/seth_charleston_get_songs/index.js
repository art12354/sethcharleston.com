var aws = require('aws-sdk');
var docClient = new aws.DynamoDB.DocumentClient();

exports.handler = (event, context, callback) => {
  var params = {
    TableName: 'seth_charleston_music'
  };
  docClient.scan(params, onScan);

  function onScan(err, data) {
    if (err) {
      console.error("Unable to scan the table. Error JSON:", JSON.stringify(err, null, 2));
      callback(null, err);
    } else {
      console.log("Scan succeeded.");
      callback(null, data.Items);
      data.Items.forEach(function(movie) {
        console.log(movie);
      });

      if (typeof data.LastEvaluatedKey != "undefined") {
        console.log("Scanning for more...");
        params.ExclusiveStartKey = data.LastEvaluatedKey;
        docClient.scan(params, onScan);
      }
    }
  }
};
