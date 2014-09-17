#!/bin/bash

################################################################################
#
# For upgrading Omeka when the old version is 1.5 or greater, and upgrading to
# versions greater than 1.5.
#
#
#
################################################################################

# End the script if any statement returns a non-true return value
set -e 
# End script if an unset variable is encountered.
set -u 

# Set colors for echo
black='\E[30;40m'
red='\x1B[1;31;40m'
green='\x1B[32;40m'
yellow='\x1B[33;40m'
blue='\x1B[1;34;40m'
magenta='\x1B[35;40m'
cyan='\x1B[36;40m'
white='\E[1;37;40m'
reset=$(tput sgr0)


CURDATE=$( date +%Y-%m-%d-%s )
GIT=$( which git )
#MYSQL=$( which mysql )
#MDUMP=$( which mysqldump )
#MADMIN=$( which mysqladmin )
#PHP=$( which php )
MYSQL="/Applications/MAMP/Library/bin/mysql"
MDUMP="/Applications/MAMP/Library/bin/mysqldump"
MADMIN="/Applications/MAMP/Library/bin/mysqladmin"
PHP="/Applications/MAMP/bin/php/php5.5.10/bin/php"


while getopts "n:o:st" opt; do
    case $opt in
        n)
            NEATVERSION="$OPTARG"
            ;;
        o)
            OMEKAVERSION="$OPTARG"
            ;;
        s)
            SKIPOMEKA="true"
            ;;
        t)
            SKIPNEAT="true"
            ;;
        \?)
            echo "Invalid argument"
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument."
            exit 1
            ;;
    esac
done
shift $(($OPTIND - 1))



################################################################################
#
#
##      FUNCTIONS
#
#
################################################################################

# Compare two floating point numbers.
#
# Usage:
# result=$( compare_floats number1 number 2 )
# if $result ; then
#     echo 'number1 is greater'
# else
#     echo 'number2 is greater'
# fi
#
# result  : the string 'true' or 'false'
# number1 : the first number to compare
# number2 : the second number to compare
function compare_floats() {
    echo | awk -v n1=$1 -v n2=$2  '{if (n1<n2) printf ("false"); else printf ("true");}' 
}

# Pass the current version first, then the array
# the function echoes the version just greater than the current version,
# i.e., the next version to upgrade to.
#
# Usage: 
# variable=$( get_next_version $num array[@] )
#
# variable : the next version greater than $num
# $num     : the current version
# array[@] : an array of all possible versions
get_next_version() {
    num=$1
    declare -a ARRAY=("${!2}")
        
    for i in ${ARRAY[@]}
    do
        if awk -v n1=$num -v n2=$i 'BEGIN{ if (n1<n2) exit 0; exit 1}'; then
            #echo "$num < $i"
            echo $i
            break
        else
            #echo "$num > $i"
            continue
        fi
    done
}

# Uses the global variables from the db.ini file and creates the compressed SQL file
# I was going to use this more than once, so wrote it as a function...
#
# Usage:
# tbldump [NAME]
#
# NAME : an optional string to identify the compressed backup from others
tbldump() {
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
    echo -e "$green Making a copy of the database. $reset"
    $MDUMP --user=${DBUSER} --password=${DBPASS} --opt ${DBNAME} $tablelist | gzip -c | cat > ${path}/${DBNAME}-${DBPREF}${CURDATE}_$1_BACKUP.sql.gz
}


# Need to run the neatline upgrade in multiple spots, so better as a function.
# Uses global variables.
#
# Usage:
# upgrade_neatline [version]
#
# version : an optional version number to upgrade neatline to, otherwise it finds the current version and upgrades to the next version
function upgrade_neatline() {
    # an array put together by getting versions from neatline github
    NEATLINES=( $( $GIT ls-remote --tags http://github.com/scholarslab/Neatline | cut -d"/" -f3 | egrep -v "[a-z]|{" ) )
    if [[ -n ${NEATVERSION:-} ]]; then
        n_upgrade=$NEATVERSION
    elif [[ -z ${1:-} ]]; then 
        n_upgrade=$( get_next_version $neatline_version NEATLINES[@] )
    else
        n_upgrade=$1
    fi


    if [[ ${SKIPNEAT:-} ]]; then
        echo
        echo -e "${magenta}Skipping Neatline upgrade${reset}"
    elif [[ ${NEATLINES[@]:(-1)} = $neatline_version ]]; then
        echo
        echo -e "${cyan}Neatline is up to date! $reset"
    else
        if [[ -d $base_dir/NewOmeka ]]; then
            OmekaDir="NewOmeka"
        else
            OmekaDir="$base_name"
        fi

        echo
        echo -e "${magenta}Checking out new Neatline plugin, version $n_upgrade.$reset"
        cd $base_dir/${OmekaDir}/plugins/
        if [[ -d $base_dir/${OmekaDir}/plugins/Neatline/ ]]; then
            rm -rf $base_dir/${OmekaDir}/plugins/Neatline/
            $GIT rm -rf Neatline || true
            $GIT submodule add -f https://github.com/scholarslab/Neatline.git Neatline/
            cd $base_dir/${OmekaDir}/plugins/Neatline/
            $GIT checkout tags/$n_upgrade
        else
            $GIT submodule add -f https://github.com/scholarslab/Neatline.git Neatline/
            cd $base_dir/${OmekaDir}/plugins/Neatline/
            $GIT checkout tags/$n_upgrade
        fi

        # Use NeatlineMaps if next version of neatline is less than or equal to 1.1.3
        # otherwise, next version is greater than 1.1.3 so use sub-plugins
        if [[ $( compare_floats 1.1.3 $n_upgrade ) == "true" ]]; then
            cd $base_dir/${OmekaDir}/plugins/
            rm -rf $base_dir/${OmekaDir}/plugins/NeatlineMaps/
            #$GIT rm -rf NeatlineMaps
            $GIT submodule add -f https://github.com/scholarslab/NeatlineMaps.git NeatlineMaps/
        else
            if [[ ! -d $base_dir/${OmekaDir}/plugins/NeatlineWaypoints ]]; then
                cd $base_dir/${OmekaDir}/plugins/
                $GIT submodule add -f https://github.com/scholarslab/nl-widget-Text.git NeatlineText/
                $GIT submodule add -f https://github.com/scholarslab/nl-widget-Simile.git NeatlineSimile/
                $GIT submodule add -f https://github.com/scholarslab/nl-widget-Waypoints.git NeatlineWaypoints/
            fi
        fi

        # Looking for exact number, so comparing as strings is OK
        if [[ $n_upgrade = "2.0.0" ]]; then
            if [[ -d $base_dir/NewOmeka ]]; then

                echo
                echo -e "$green Moving old folder to ${magenta}old-${base_name}${reset}, and moving the new copy to ${magenta}${base_name} $reset"
                # Out with the old, in with the new...
                mv $path $base_dir/old-${base_name}
                mv $base_dir/NewOmeka $path
            fi

            # Delete NeatlineMaps plugins
            $MYSQL --user=${DBUSER} --password=${DBPASS} --host=${DBHOST} --port=${DBPORT} ${DBNAME} --execute="DELETE FROM ${DBPREF}plugins WHERE name='NeatlineMaps';"

            ########################################
            # Run the following to get Neatline exhibits to show up.
            echo
            echo -e "$red Run the database upgrade script! And upgrade and activate plugins! Type 'y' and press enter when done. $reset"
            read -p "# " ready
            while [ "$ready" != "y" ]; do
                echo "Type 'y' and press enter to continue."
                read -p "# " ready
            done

            echo 
            echo -e "$green Running migration for Neatline Exhibits $reset"
            # Add lines to upgrade/migrate script.
            migrate='$fc = Zend_Registry::get("bootstrap")->getPluginResource("FrontController")->getFrontController(); $fc->getRouter()->addDefaultRoutes();'

            # For linux systems (CentOS) remove the empty double quotes after -i
            sed -i "" "80s/.*/${migrate}/" ${path}/plugins/Neatline/migrations/2.0.0/Neatline_Migration_200.php

            $MYSQL --user=${DBUSER} --password=${DBPASS} --host=${DBHOST} --port=${DBPORT} ${DBNAME} --execute="UPDATE ${DBPREF}processes SET status='starting' WHERE id=1;"
            $PHP ${path}/application/scripts/background.php -p 1 

            #$MYSQL --user=${DBUSER} --password=${DBPASS} --host=${DBHOST} --port=${DBPORT} ${DBNAME} --execute="DROP TABLE IF EXISTS ${DBPREF}neatline_maps_servers; DROP TABLE IF EXISTS ${DBPREF}neatline_maps_services""
             
        fi # end special stuff if version 2.0.0

    fi # end check if neatline is up to date
}

################################################################################
#
#
##     END   FUNCTIONS
#
#
################################################################################





################################################################################
#
#
##     BEGIN INTERACTIVE PART OF SCRIPT
#
#
################################################################################


# Get the path to the installation.
if [[ -z ${1:-} ]]; then 
    echo -n "Enter the full path to the installation. "
    read -e path
else
    path=$1
fi

base_name=$( basename ${path} )
base_dir=$( dirname ${path} )



########################################
# Make copy of the site and database before any changes are made
if [[ ! -e $path/db.ini ]]; then
    echo -e "${red}This directory does not contain a db.ini file. Are you sure it has an Omeka install?${reset}"
    exit 1
fi

# Get db.ini info
DBUSER=$( cat ${path}/db.ini | grep "^username" | awk -F\" '{print $(NF-1)}' )
DBPASS=$( cat ${path}/db.ini | grep "^password" | awk -F\" '{print $(NF-1)}' )
DBNAME=$( cat ${path}/db.ini | grep "^dbname" | awk -F\" '{print $(NF-1)}' )
DBPREF=$( cat ${path}/db.ini | grep "^prefix" | awk -F\" '{print $(NF-1)}' )
DBHOST=$( cat ${path}/db.ini | grep "^host" | awk -F\" '{print $(NF-1)}' )
DBPORT=$( cat ${path}/db.ini | grep "^port" | awk -F\" '{print $(NF-1)}' )

# Make backup of database
tbldump "ORIGINAL"

# Make a copy of the directory in case the script destroys the site during upgrade.
echo -e "$green Making a copy of the files$reset"
cd ${base_dir}
zip -qr ${base_dir}/${base_name}-copy.zip ${base_name}


# get rid of old copies
if [[ -d $base_dir/old-${base_name} ]]; then
    rm -rf $base_dir/old-${base_name}
fi



########################################
# Get current versions of...

# OMEKA
if [[ -e ${path}/paths.php ]]; then
    omeka_version=$( cat ${path}/paths.php | grep "OMEKA_VERSION"  | awk -F\' '{print $(NF-1)}' )
else
    omeka_version=$( $MYSQL --user=${DBUSER} --password=${DBPASS} --host=${DBHOST} --port=${DBPORT} ${DBNAME} --raw --silent --silent --execute="SELECT value FROM ${DBPREF}options WHERE name='omeka_version';" )
fi


# NEATLINE
if [[ -e ${path}/plugins/Neatline/plugin.ini ]]; then
    neatline_version=$( cat ${path}/plugins/Neatline/plugin.ini | grep "^version" | awk -F\" '{print $(NF-1)}' )
else
    neatline_version=$( $MYSQL --user=${DBUSER} --password=${DBPASS} --host=${DBHOST} --port=${DBPORT} ${DBNAME} --raw --silent --silent --execute="SELECT version FROM ${DBPREF}plugins WHERE name='Neatline';" )
fi



########################################
# Run the upgrades

# if Omeka is at 1.5.3, upgrade neatline only until it gets to 1.1.3
# So, testing for Omeka at version 1.5.3 and Neatline version less than or equal to 1.1.2
#elif [[ $omeka_version == "1.5.3" && $(compare_floats 1.1.2 $neatline_version) == "true" ]]; then
#    echo -e "${yellow}Neatline needs to be upgraded before upgrading to the next Omeka version.\nPlease run this script again to upgrade Omeka.${reset}"
#    upgrade_neatline 1.1.3

#else

    ########################################
    # Upgrade Omeka to the next version

    # Deactivate plugins
    $MYSQL --user=${DBUSER} --password=${DBPASS} --host=${DBHOST} --port=${DBPORT} ${DBNAME} --execute="UPDATE ${DBPREF}plugins SET active=0 WHERE 1;" 

    cd $base_dir

    # an array put together by getting versions from omeka github
    OMEKAS=( $($GIT ls-remote --tags https://github.com/omeka/Omeka | cut -d"/" -f 3 | sed 's/^v//' | egrep -v "[a-z]|{") )
    # get the next available version of Omeka
    o_upgrade=$( get_next_version $omeka_version OMEKAS[@] )

    # if the -o option is set, use the supplied version
    if [[ -n ${OMEKAVERSION:-} ]]; then
        o_upgrade=$OMEKAVERSION

    # if current omeka version is less than 1.5.3, then upgrade omeka to 1.5.3
    elif [[ $(compare_floats $omeka_version 1.5.3) == "false" ]]; then
        o_upgrade="1.5.3"

    # if current omeka version is 1.5.3, then upgrade omeka to 2.0.4
    elif [[ $omeka_version == "1.5.3" ]]; then
        o_upgrade="2.0.4"

    # if current omeka version is equal to 2.0.4, then upgrade omeka to 2.1.4
    elif [[ $omeka_version  == "2.0.4" ]]; then
        o_upgrade="2.1.4"

    # if current omeka version is equal to 2.1.4, then upgrade omeka to the latest
    elif [[ $omeka_version == "2.1.4" ]]; then
        o_upgrade=${OMEKAS[@]:(-1)}
    fi

    if [[ ${SKIPOMEKA:-} ]]; then
        echo
        echo -e "${magenta}Skipping Omeka upgrade.${reset}"
        o_upgrade=$omeka_version
    # compare current version with last element in OMEKAS array 
    elif [[ ${OMEKAS[@]:(-1)} == $omeka_version ]]; then
        echo -e "${cyan}Omeka is up to date!${reset}"
        o_upgrade=$omeka_version

    else
        echo -e "${magenta}Upgrading Omeka to version $o_upgrade.${reset}"
        echo
        # Delete botched previous attempts
        if [ -d $base_dir/NewOmeka ]; then
            rm -rf $base_dir/NewOmeka
        fi
        # Clone Omeka
        $GIT clone https://github.com/omeka/Omeka.git NewOmeka

        cd NewOmeka

        # Get correct version of Omeka and themes/plugins
        $GIT checkout tags/v${o_upgrade}
        $GIT submodule init
        $GIT submodule update

        echo
        echo -e "$green Fix config files.$reset"
        # Get db.ini and fix .htaccess and config.ini
        cp $path/db.ini $base_dir/NewOmeka/
        mv $base_dir/NewOmeka/application/config/config.ini.changeme $base_dir/NewOmeka/application/config/config.ini
        mv $base_dir/NewOmeka/.htaccess.changeme $base_dir/NewOmeka/.htaccess

        echo -e "$green Copy files.$reset"
        # Pre 2.x Omeka used archive/files/, post 2.0 uses files/original/
        if [[ $o_upgrade == "2.0.4" ]]; then
            cp -r $path/archive/ $base_dir/NewOmeka/files/
            rm -rf $base_dir/NewOmeka/files/original/
            mv $base_dir/NewOmeka/files/files/ $base_dir/NewOmeka/files/original/
        elif [[ $( compare_floats 1.5.3 $o_upgrade ) == "true" ]]; then
            cp -r $path/archive/ $base_dir/NewOmeka/archive/
        else
            cp -r $path/files/ $base_dir/NewOmeka/files/
        fi

        echo -e "$green Copy Plugins.$reset"
        # Copy over plugins and themes. Don't copy "Neatline" or the default plugins/themes.
        cd $path/plugins/
        plugin_list=( $( ls -dA */ ) )
        for dir in "${plugin_list[@]}"; do
            if [[ ${SKIPNEAT:-} ]]; then
                if [[ "$dir" != *"Coins"* && "$dir" != *"SimplePages"* && "$dir" != *"ExhibitBuilder"* ]]; then
                    cp -r $path/plugins/$dir $base_dir/NewOmeka/plugins/$dir
                fi
            else
                if [[ "$dir" != *"Neatline"* && "$dir" != *"Coins"* && "$dir" != *"SimplePages"* && "$dir" != *"ExhibitBuilder"* ]]; then
                    cp -r $path/plugins/$dir $base_dir/NewOmeka/plugins/$dir
                fi
            fi
        done

        echo -e "$green Copy themes.$reset"
        # Copy themes, except for "neatline", and default installed themes
        cd $path/themes/
        theme_list=( $( ls -dA */ ) )
        for dir in "${theme_list[@]}"; do
            if [[ "$dir" != *"neatline"* && "$dir" != *"berlin"* && "$dir" != *"default"* && "$dir" != *"seasons"* ]]; then
                cp -r $path/themes/$dir $base_dir/NewOmeka/themes/$dir
            fi
        done

        # If omeka is 1.5.3 or less, then copy over the old themes
        if [[ $( compare_floats 1.5.3 $o_upgrade ) == "true" ]]; then
            cp -r $path/themes/neatlinetheme/ $base_dir/NewOmeka/themes/neatlinetheme/
            cp -r $path/themes/neatlinethin/ $base_dir/NewOmeka/themes/neatlinethin/
        fi

        if [[ ! -d $base_dir/NewOmeka/themes/astrolabe ]]; then
            cd $base_dir/NewOmeka/themes/
            $GIT submodule add -f https://github.com/scholarslab/astrolabe.git
        fi

    fi # end update omeka

    # upgrade the neatline plugin
    if [[ $o_upgrade == "1.5.3" ]]; then
        upgrade_neatline 1.1.3
    elif [[ $o_upgrade == "2.0.4" ]]; then
        upgrade_neatline 2.0.0
    elif [[ $o_upgrade == "2.1.4" ]]; then
        upgrade_neatline  2.1.3
    elif [[ $(compare_floats $o_upgrade 2.2) == "true" ]]; then
        upgrade_neatline 2.3.0
    else
        upgrade_neatline
    fi
#fi # end omeka upgrade section



########################################
# Out with the old, in with the new
echo
if [[ -d $base_dir/NewOmeka ]]; then

    echo
    echo -e "$green Moving old folder to ${magenta}old-${base_name}${reset}, and moving the new copy to ${magenta}${base_name} $reset"
    mv $path $base_dir/old-${base_name}
    mv $base_dir/NewOmeka $path
fi



########################################
# Upgrade the database of the new Omeka and the plugins.

# TODO
    # Code up auto upgrade the plugins and activate the plugins

# Activate plugins
#$MYSQL --user=${DBUSER} --password=${DBPASS} --host=${DBHOST} --port=${DBPORT} ${DBNAME} --execute="UPDATE ${DBPREF}plugins SET active=1 WHERE 1;" 



########################################
if [[ -z ${SKIPOMEKA:-} || -z ${SKIPNEAT:-} ]]; then
    echo
    echo -e "${yellow}You may need to run the database upgrade script from the web admin page.\nYou may also need to upgrade and re-activate any needed plugins.$reset"
fi
exit 0
