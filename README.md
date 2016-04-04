# TrucksuUmbrella

## Running on Windows

- Run all git bash shells with admin privileges
- `npm install --no-bin-links`, otherwise you get symlink errors

### Sniffing HTTP requests on Loopback interface

Taken from [this StackOverflow answer](http://www.netresec.com/?page=RawCap):

```
# Run in cmd.exe (possibly with admin privileges)
cmd1: RawCap.exe -f 127.0.0.1 dumpfile.pcap

# Run in git bash (possibly wih admin privileges)
cmd2: tail -c +0 -f dumpfile.pcap | Wireshark.exe -k -i -
```
