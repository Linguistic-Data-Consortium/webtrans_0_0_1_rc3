# webtrans_0_0_1_rc3
webtrans for distribution

LDC's transcription tool, normally called webtrans, is derived from software called UA,
within a repo called `ua`.  So in the rest of this README, where you see the name UA or
the directory `ua`, you can interpret that as the current app/repo/directory.  This README
is only concerned with the installation of the software.

# UA

LDC's Universal Annotator is web based, customizable annotation software, that can be
installed locally or in the cloud.  UA is a Ruby on Rails app, although like
most modern web apps it's largely written in Javascript.

## Local Installation

UA is a web app, so using it locally means the server side software is also local.
In other words, to simulate a normal desktop application installed on your local
machine, you actually just use your browser to connect to a local server.
Local installation is made much easier with the Docker ecosystem.  In short, you
install docker first, then docker installs everything else.

### Docker

There's no single way to install docker, even on one platform.  On Mac OS, we
recommend creating a dockerhub account and installing Docker Desktop.  Check out
docker.com, hub.docker.com, and other tutorials on docker to see what's best for
you.  In the end you need the `docker-compose` command available on your command line.
The first time you run docker it may take a while since other software is installed.
On subsequent runs the app should start fairly quickly.  In the terminal where it's
started, Control-C should be good enough to shut everything down.  For more details,
see the documentation for the `docker` and `docker-compose` commands.

### Install

Once you have docker:

1. Clone the repo.
2. `cd ua`
3. `docker-compose up`
4. browse to http://localhost:3005
5. choose Single User or Multi User mode

### Single User Mode

UA can handle multiple users, but if you're installing this locally, this feature
may be of no use to you.  Single User Installation mode assumes
there will only ever be one user, which simplifies many things for you.  The following
instructions assume you will choose this mode.  Clicking the Initialize button here
creates a user with full privileges (admin user) and logs you in automatically.

### Multi User Mode

1. Click Create Server
2. Optionally enter a server name (it can be left blank) and click Save
3. Click Create Account
4. Enter the info and Click Sign in
5. Set your user to admin and refresh (see below)

In Multi User mode, the default, new users don't automatically have any permissions.
If you're the one installing the software, you probably want to log in to the
database and make yourself an admin.   For a local install, run the following
in a separate shell (but also from the `ua` directory).

    docker-compose exec web rails c
    
This puts you into a rails shell, which has access to the database.  In that shell,
run the following.

    User.first.toggle! :admin
    
You can exit the rails shell with Control-D.

### Restarting the app

As stated above, `docker-compose up` starts the app by starting several docker containers at once.
If this terminal is still open, Control-C should shut down the app, but you can also
run `docker-compose down` from the same directory to shut down all the containers.  For many people, this is as much
as you need to know, but many more options are available with docker and docker-compose,
and checking out the documentation is recommended.

### New Local Installations

Sometimes it might be desirable to create a new installation of the software.  This
can't be done by simply copying (or cloning) the code to a new directory and running
from there, because the app will end up connecting to the same database if you're on the same machine.  One option
would be to wipe the database, but sometimes that's not desirable either.  You
might like to keep the database you have, but also see what happens when starting
over from scratch; therefore you can make a new database.  The environment file `.envv/development/database`
names a database `myapp_development` which tells the app which database to connect to.
If you want to create a new database, make sure the app is already running,
and run the following command in a separate shell after replacing `NAME` with a new database name.

    docker-compose exec web rails database:change[NAME]
    
This will rewrite the environment file with the specified database name, which is sufficient
to connect to that database but not to actually create it.  The first time the postgres docker image
is used, the named database (`myapp_development` in this case) is created, but that only works the first time.
The above command for rewriting the environment file will also print out a
command which you must use to create the new database.  Run the given command, restart the app, and the app
will now be pointing to the new database.  To switch back to `myapp_development`, you can
simply run

    docker-compose exec web rails database:change[myapp_development]
    
and restart the app.  This is the original database so you don't need to run the printed creation command.

### Production

The included Dockerfile has 4 stages, but the docker-compose.yml file is only targeting the second stage,
called `dev`.  The later stages illustrate a possible production build, but it's only an illustration,
and may or may not be appropriate for your situation.

