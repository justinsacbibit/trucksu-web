
## User status

- Add support for GMT, supporter statuses

## Score submission

### Completed
- Calculate accuracy update

### Failed / retry
- Should total hits be updated?

## Friends

- Add support for friends list

## Channels

- Add support for more, non-hardcoded channels
- Correct channelJoin logic
  - Join ChannelServer
- Correct channelPart logic
  - Leave ChannelServer
- Correct send
  - Send only to users in the channel

## Ops

### Deployment/restart

- POST to [localhost:4002/ops/restart](localhost:4002/ops/restart) endpoint before restarting
  - this will send a `server_restart` packet to all connected users

## Release streams

- Support HTTPS for Stable, Beta, Cutting Edge
