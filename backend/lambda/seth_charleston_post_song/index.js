var aws = require('aws-sdk');
var docClient = new aws.DynamoDB.DocumentClient();

exports.handler = (event, context, callback) => {
  var params = {
    TableName: 'seth_charleston_music',
    Item: {
      'song': event.song,
      'link': event.link,
      'release': event.release
    }
  };

  docClient.put(params, function(err, data) {
    if (err) {
      console.log("Error", err);
      callback(null, "coming from lamda: " + err);
    } else {
      console.log("Success", data);
      callback(null, "added " + event);
    }
  });
};
