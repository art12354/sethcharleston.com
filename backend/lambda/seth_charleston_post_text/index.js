var aws = require('aws-sdk');
var docClient = new aws.DynamoDB.DocumentClient();

exports.handler = (event, context, callback) => {
  var params = {
    RequestItems: {
      'seth_charleston_text': []
    }
  };
  console.log(event);
  console.log(context);
  for (var item of event) {
    params.RequestItems.seth_charleston_text.push(
      {
        'PutRequest': {
          'Item': {
            'location': item.location,
            'text': item.text
          }
        }
      }
    );
  }

  docClient.batchWrite(params, function(err, data) {
    if (err) {
      console.log(err);
      callback(null, err);
    } else {
      console.log(data);
      callback(null, "added " + event);
    }
  });
};
