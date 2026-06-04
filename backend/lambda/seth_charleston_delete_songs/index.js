var aws = require('aws-sdk');
var docClient = new aws.DynamoDB.DocumentClient();

exports.handler = (event, context, callback) => {
  var params = {
    TableName: 'seth_charleston_music',
    Key: {
      'song': event.song
    }
  };
  console.log(event.song);
  docClient.delete(params, function(err, data) {
    if (err) {
      console.log("Error", err);
      callback(null, err);
    } else {
      console.log("Success", data);
      callback(null, "deleted " + event);
    }
  });
};
