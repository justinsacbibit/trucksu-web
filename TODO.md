- Screenshot upload `POST /osu/web/osu-screenshot.php`
- Favourites
- User IDs of 1 and 2 are reserved for BanchoBot and peppy

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

- ~~Private messaging~~ (I think it's working)
- When joining, the welcome message in #osu is not cased correctly
- Add support for more, non-hardcoded channels

## Ops

### Deployment/restart

- POST to [localhost:4002/ops/restart](localhost:4002/ops/restart) endpoint before restarting
  - this will send a `server_restart` packet to all connected users

## Release streams

- Support HTTPS for Stable, Beta, Cutting Edge
  - Import rootCA.crt under Current User
