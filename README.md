# Trucksu Web

trucksu-web is the main web application for Trucksu. It contains:
- front-end and back-end for the website
- osu! avatar server (used by osu! client)
- osu! replay/score endpoints (used by osu! client)

The application consists of an Elixir/Phoenix server on the back-end, and a React/Redux app on the front-end.

["Elixir is a dynamic, functional language designed for building scalable and maintainable applications."](http://elixir-lang.org/)

[Phoenix](http://www.phoenixframework.org/) is a web framework, similar to Ruby on Rails, for Elixir.

Webpack is used to build the JS app.

##### Developing

Within this repo directory, an `src` directory should be created after provisioning with Vagrant. You can edit the source code within `src/trucksu-web`.

The source code for the front-end can be found in `web/static/js/`.

Note: If you're not developing Bancho, you may want to change the forwarded ports in the Vagrantfile. For [these two lines](https://github.com/justinsacbibit/trucksu-vagrant/blob/7297e4bb5f5e9ed5605d1f7442cfbb539a1bb166/Vagrantfile#L47-48), change the host ports from 80 to 8080 and from 443 to 8443. If you change these while the vm is running, use `vagrant reload` in a shell to update the vm.

##### Running

You'll need two shells/command prompts to run trucksu-web. One will be for the Phoenix app

```sh
# NOTE: One of these steps might prompt you install rebar, say Y

$ vagrant ssh
$ cd src/trucksu-web

# The following block of commands only needs to be run once
$ mix deps.get # run this again if you update dependencies in mix.exs
# Set up the database
$ mix ecto.create
$ mix ecto.migrate
$ mix run priv/repo/seeds.exs

$ mix phoenix.server
```

The other will be for Webpack

```sh
$ vagrant ssh
$ cd src/trucksu-web
$ npm install
$ npm run dev-win
```

If they both run, try visited [http://localhost:8080](http://localhost:8080) in your browser! (Or [http://localhost](http://localhost) if you didn't update the ports in the Vagrantfile)

## Running on Windows

- Run all git bash shells, cmd.exe with admin privileges
- If vagrant says port 80 is in use, try `net stop http` in an admin shell
- If vagrant says port 443 is in use, try quitting Skype
- `npm install --no-bin-links`, otherwise you get symlink errors

### Sniffing HTTP requests on Loopback interface

Taken from [this StackOverflow answer](http://www.netresec.com/?page=RawCap):

```
# Run in cmd.exe (possibly with admin privileges)
cmd1: RawCap.exe -f 127.0.0.1 dumpfile.pcap

# Run in git bash (possibly wih admin privileges)
cmd2: tail -c +0 -f dumpfile.pcap | Wireshark.exe -k -i -
```
