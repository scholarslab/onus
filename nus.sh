#!/bin/bash

################################################################################
#
# For upgrading Omeka when the old version is 1.5 or greater, and upgrading to
# versions greater than 1.5.
#
#
#
################################################################################

CURDATE=$( date +%Y-%m-%d-%s )
RUNDIR=$( pwd )
GIT=$( which git )
MYSQL=$( which mysql )
MDUMP=$( which mysqldump )
MADMIN=$( which mysqladmin )

NEATLINES=$( git ls-remote http://github.com/scholarslab/Neatline | grep tags | grep -E -v '{|rc|alpha' | cut -d"/" -f3 )

# Get the path to the installation.
if [[ -z "$1" ]]; then 
    echo -n "Enter the full path to the installation. "
    read -e path
else
    path=$1
fi

base_name=$( basename ${path} )
base_dir=$( dirname ${path} )

########################################
# Make copy of the site and database

# Get db.ini info
DBUSER=$( cat ${path}/db.ini | grep "^username" | awk -F\" '{print $(NF-1)}' )
DBPASS=$( cat ${path}/db.ini | grep "^password" | awk -F\" '{print $(NF-1)}' )
DBNAME=$( cat ${path}/db.ini | grep "^dbname" | awk -F\" '{print $(NF-1)}' )
DBPREF=$( cat ${path}/db.ini | grep "^prefix" | awk -F\" '{print $(NF-1)}' )
DBHOST=$( cat ${path}/db.ini | grep "^host" | awk -F\" '{print $(NF-1)}' )
DBPORT=$( cat ${path}/db.ini | grep "^port" | awk -F\" '{print $(NF-1)}' )


# Get list of tables with just the desired prefix
list=( $( $MYSQL --user=${DBUSER} --password=${DBPASS} --host=${DBHOST} --port=${DBPORT} ${DBNAME} --raw --silent --silent --execute="SHOW TABLES;" ) )

for tablename in ${list[@]}
do
    # Get just the tables that match the prefix
    if [[ "$tablename" =~ "$DBPREF" ]]; then
        tablelist+="$tablename "
    fi
done

# Make an SQL dump of the selected tables.
echo -e "Making a copy of the database."
#$MDUMP --user=${DBUSER} --password=${DBPASS} --opt ${DBNAME} $tablelist > ${path}/${DBNAME}${DBPREF}-${CURDATE}_BACKUP.sql


# Make a copy of the directory in case the script destroys the site during upgrade.
echo -e "Making a copy of the files"
cd ${base_dir}
#zip -qr ${base_dir}/${base_name}-copy.zip ${base_name}


########################################


########################################
# Create a newer version of Omeka

echo -e "Get new version of Omeka"
cd $base_dir

# Get current Omeka version
omeka_version=$( $MYSQL --user=${DBUSER} --password=${DBPASS} --host=${DBHOST} --port=${DBPORT} ${DBNAME} --raw --silent --silent --execute="SELECT value FROM ${DBPREF}options WHERE name='omeka_version';" )

if [[ $omeka_version < 2.0 ]]; then
    new_version="stable-2.0"
    echo "Omeka will be upgraded to $new_version."
elif [[ $omeka_version < 2.1 ]]; then
    new_version="stable-2.1"
    echo "Omeka will be upgraded to $new_version."
elif [[ $omeka_version < 2.2 ]]; then
    new_version="stable-2.2"
    echo "Omeka will be upgraded to $new_version."
fi

# Clone Omeka
$GIT clone https://github.com/omeka/Omeka.git

cd Omeka

# Get correct version of Omeka and themes/plugins
$GIT checkout $new_version
$GIT submodule init
$GIT submodule update

exit
# Get db.ini and fix .htaccess and config.ini
cp $path/db.ini $base_dir/Omeka/
sed -i -e "s/${DBNAME}/${DBNAME}_NEW/" $base_dir/Omeka/db.ini
mv $base_dir/Omeka/application/config/config.ini.changeme $base_dir/Omeka/application/config/config.ini
mv $base_dir/Omeka/.htaccess.changeme $base_dir/Omeka/.htaccess

# Pre 2.x Omeka used archive/files/, post 2.0 uses files/original/
if [[ -d $path/archive ]]; then
    cp -r $path/archive/ $base_dir/Omeka/files/
    mv $base_dir/Omeka/files/files/ $base_dir/Omeka/files/original/
elif [[ -d $path/files/ ]]; then
    cp -r $path/files/ $base_dir/Omeka/files/
fi

# Copy over plugins and themes. Don't copy "Neatline" or the default plugins/themes.
cd $path/plugins/
plugin_list=( $( ls -dA */ ) )
for dir in "${plugin_list[@]}"; do
    if [[ "$dir" != *"Neatline"* && "$dir" != *"Coins"* && "$dir" != *"SimplePages"* && "$dir" != *"ExhibitBuilder"* ]]; then
        cp -R $path/plugins/$dir $base_dir/Omeka/plugins/
    fi
done

# Copy themes, except for "neatline", and default installed themes
cd $path/themes/
theme_list=( $( ls -dA */ ) )
for dir in "${theme_list[@]}"; do
    if [[ "$dir" != *"neatline"* && "$dir" != *"berlin"* && "$dir" != *"default"* && "$dir" != *"seasons"* ]]; then
        cp -R $path/themes/$dir $base_dir/Omeka/themes/
    fi
done


neatline_version=$( $MYSQL --user=${DBUSER} --password=${DBPASS} --host=${DBHOST} --port=${DBPORT} ${DBNAME} --raw --silent --silent --execute="SELECT version FROM ${DBPREF}plugins WHERE name='Neatline';" )

if [[ $neatline_version < 2.0 ]]; then
    neat_version='2.0'
    echo "$neatline_version < 2.0"
elif [[ $neatline_version < 2.1 ]]; then
    neat_version='2.1'
    echo "$neatline_version < 2.1"
elif [[ $neatline_version < 2.2 ]]; then
    neat_version='2.2'
    echo "$neatline_version < 2.2"
elif [[ $neatline_version < 2.3 ]]; then
    neat_version='2.3'
    echo "$neatline_version < 2.3"
fi

cd $base_dir/Omeka/plugins/
git submodule add -f https://github.com/scholarslab/Neatline.git Neatline
cd Neatline
git checkout $neat_version


# Deactivate plugins
$MYSQL --user=${DBUSER} --password=${DBPASS} --host=${DBHOST} --port=${DBPORT} ${DBNAME} --execute="UPDATE ${DBPREF}plugins SET active=0 WHERE 1;" 
# Delete NeatlineMaps plugins
$MYSQL --user=${DBUSER} --password=${DBPASS} --host=${DBHOST} --port=${DBPORT} ${DBNAME} --execute="DELETE FROM ${DBPREF}plugins WHERE name='NeatlineMaps'; DROP TABLE IF EXISTS ${DBPREF}neatline_maps_servers; DROP TABLE IF EXISTS ${DBPREF}neatline_maps_services" 

# Make a dump of the database with plugins deactivated and tables deleted
$MDUMP --user=${DBUSER} --password=${DBPASS} --opt ${DBNAME} $tablelist > ${RUNDIR}/${DBNAME}${DBPREF}-NoPluginsActive_BACKUP.sql

# Create the new database for the updated version
$MYSQL --user=${DBUSER} --password=${DBPASS} --host=${DBHOST} --port=${DBPORT} ${DBNAME} --execute="CREATE DATABASE ${DBNAME}_NEW;" 
# Import the old database into the new.
$MYSQL --user=${DBUSER} --password=${DBPASS} --host=${DBHOST} --port=${DBPORT} ${DBNAME}_NEW < ${RUNDIR}/${DBNAME}${DBPREF}-NoPluginsActive_BACKUP.sql



# Out with the old, in with the new...
mv $path $base_dir/old-${base_name}
mv $base_dir/Omeka $path

########################################



########################################
# Upgrade the database of the new Omeka 

#read -p "Enter FQDN for Omeka install: " url

#curl -o /dev/null  ${url}/?
