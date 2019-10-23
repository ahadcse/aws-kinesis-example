
const AWS = require('aws-sdk')
const kinesis = new AWS.Kinesis()

const getStreamName = (record) => {
  const [ , streamName ] = record.eventSourceARN.split('/')
  return streamName
}

const decodeData = (record) => {
  const data = record.kinesis.data
  const decoded = Buffer.from(data, 'base64').toString()
  return JSON.parse(decoded)
}

const logger = async (event) => {
  console.log(`event: ${JSON.stringify(event)}`)
  const streamData = []
  event.Records.forEach((record) => {
    const name = getStreamName(record)
    console.log('Stream name',name)
    const data = decodeData(record)
    console.log('Data', data)
    streamData.push(data)
  })
  console.log('Stream', streamData)
  await Promise.resolve()
  return streamData
}

const pinger = async (event) => {
  console.log(`pinger event: ${JSON.stringify(event)}`, 'handler')
  const time = (new Date()).toISOString()
  const params = {
    Data: JSON.stringify({ ping: 'ping', time }),
    PartitionKey: '1',
    StreamName: 'StreamingPlatform'
  }
  try {
    await kinesis.putRecord(params).promise()
  } catch (e) {
    return e
  }
  return 'pinged'
}

module.exports = {
  logger,
  pinger
}
