# STIRRS R Shiny

The GitLab repository for the R Shiny content for the STIRRS project. Note: this is different from the Omeka S repository. Kelly Kendro is the contact for this project. 

Notes on using this with R-Shiny:

Create a GitLab repo with the following folder structure:

```
./shiny/
    |_ app.R
```

Additionally, you may also create the following folder structure to "override" the s2i folders I have provided, and edit the assemble script to put your code elsewhere, though the permissions of the user running the container will be limited.

```
./.s2i/
    |_ bin/
        |_ run
        |_ assemble
        |_ usage
        |_ save_artifacts
```

If this method is chosen, your `.s2i/bin/run` script MUST contain the following:

```bash
USER_NAME="shiny"
if ! whoami &> /dev/null; then
if [ -w /etc/passwd ]; then
echo "----- User name not defined, creating $USER_NAME user -----"
echo "$USER_NAME:x:$(id -u):0:$USER_NAME user:${HOME}:/sbin/nologin" >> /etc/passwd
fi
fi

# If user name is 'default' then make it shiny
if [ "$(whoami)" = "default" ]; then
echo "----- User name defined as 'default', changing to $USER_NAME -----"
cp /etc/passwd /tmp/passwd
sed -i 's/default/$USER_NAME/' /tmp/passwd
cp /tmp/passwd /etc/passwd
rm /tmp/passwd
fi

###<put things you want to do here>###


echo "---- Starting web server ----"

exec /opt/shiny-server/bin/shiny-server
```

Otherwise, the server will fail to start, because the user that gets created will not be formatted properly, and lack permissions to make any changes or start the server.

Additionally, install any R packages in the `.s2i/bin/assemble` file.

## OpenShift

To deploy on OpenShift:

1. Create an application via "Import from Git" and enter your repository's information and keys (via Secrets) as necessary.
2. Select Builder Image as the Import Strategy and Shiny Debian as the Builder Image.
3. Select to generate a DeploymentConfig resource type.
4. Select Build configuration and enter "http://squidproxy-01.lsait.lsa.umich.edu:3128" as the value for an HTTP_PROXY and HTTPS_PROXY environment variables.
