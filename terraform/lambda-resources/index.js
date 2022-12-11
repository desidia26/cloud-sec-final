const zlib = require('zlib');
const AWS = require('aws-sdk');
const docClient = new AWS.DynamoDB.DocumentClient();
const ec2 = new AWS.EC2();
const sns = new AWS.SNS();
const TABLE_NAME = process.env.TABLE_NAME;
const ACL_ID = process.env.ACL_ID;
const TOPIC_ARN = process.env.TOPIC_ARN;


exports.handler = async (event, context) => {
    const payload = Buffer.from(event.awslogs.data, 'base64');
    const parsed = JSON.parse(zlib.gunzipSync(payload).toString('utf8'));
    for(let i = 0; i < parsed.logEvents.length; i++) {
      const regexp = /\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b/;
      const IP = parsed.logEvents[i].message.match(regexp)[0];
      const upsertedIPEntry = await upsertIpEntry(IP);
      if (upsertedIPEntry && upsertedIPEntry.incidents > 10 && !upsertedIPEntry.ruleNumber) {
        let nextRuleNUm = await getNextACLRuleNum();
        blockIP(IP, nextRuleNUm);
      }
    }
    return `Successfully processed ${parsed.logEvents.length} log events.`;
};


async function upsertIpEntry(IP){
  const currentDateTimeInSeconds = new Date().getTime() / 1000;
  const params = {
    TableName: TABLE_NAME,
    Key: {
        "ip": IP
    },
    UpdateExpression: "SET incidents = if_not_exists(incidents, :start) + :inc, expire_time = :expireTime",
    ExpressionAttributeValues: {
        ":start": 1,
        ":inc": 1,
        ":expireTime": currentDateTimeInSeconds + (60 * 60 * 6)
    },
    ReturnValues: "ALL_NEW"
  };
  let updatedItem;
  try {
    updatedItem = await docClient.update(params).promise();
  } catch (err) {
    console.error(err);
  }
  return updatedItem.Attributes;
}

async function blockIP(IP, nextRuleNum) {
  var params = {
    CidrBlock: `${IP}/32`, 
    Egress: false, 
    NetworkAclId: ACL_ID, 
    Protocol: "-1", 
    RuleAction: "DENY", 
    RuleNumber: nextRuleNum
  };
  ec2.createNetworkAclEntry(params, function(err, data) {
    if (err) console.log(err, err.stack); // an error occurred
    else     console.log(data);           // successful response
  });
  publishAttackMessage(IP);
}

async function getNextACLRuleNum() {
  var params = {
    NetworkAclIds: [
      ACL_ID
    ]
  };
  let result = await ec2.describeNetworkAcls(params).promise();
  console.log(result.NetworkAcls[0].Entries)
  return result.NetworkAcls[0].Entries.length + 1;
}

function publishAttackMessage(IP) {
  var params = {
    Message: `Attack received from IP: ${IP}. Blocking in ACL: ${ACL_ID}`, /* required */
    Subject: 'Attack detected!',
    TopicArn: TOPIC_ARN
  };
  sns.publish(params, function(err, data) {
    if (err) console.log(err, err.stack); // an error occurred
    else     console.log(data);           // successful response
  });
}