#!/bin/bash

# Automatically get settings. Try to guess url.
DBPASSWORD=`grep -oP -m1 '(?<=password=).*(?=$)' ~/.my.cnf`
DEFAULTURL=`uberspace web domain list | tail -n1`

read -p "Please enter your url (default is $DEFAULTURL): " URL
URL=${URL:-$DEFAULTURL}

# Just try to add it. If it's already there it will gracefully fail
uberspace web domain add $URL

# Look for a free Port...

RESULT=false

while [ -n "$RESULT" ]
do
PORT=$(( $RANDOM % 4535 + 61000))
RESULT=`netstat -tulpen | grep $PORT`
done

# Install ghost and create .htaccess and service files
npm install -g ghost-cli@latest
ghost install -d ~/ghost --no-stack --url https://$URL --port $PORT --db mysql --dbuser $USER --dbpass $DBPASSWORD --dbname $USER --process local --no-start --no-setup-mysql --no-setup-nginx --no-setup-ssl --no-setup-systemd --no-setup-linux-user --no-prompt

mkdir -p /var/www/virtual/$USER/$URL
cat <<__EOF__ >> /var/www/virtual/$USER/$URL/.htaccess
DirectoryIndex disabled
RewriteEngine On
RewriteRule ^(.*) http://localhost:$PORT/\$1 [P]
__EOF__

cat <<__EOF__ >> ~/etc/services.d/ghost.ini
[program:ghost]
directory=/home/$USER/ghost
command=/home/$USER/bin/ghost run
autorestart=true
environment = NODE_ENV="production"
__EOF__

supervisorctl reread
supervisorctl update
