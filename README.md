This script runs the commands needed to upgrade Omeka from 1.5 to the latest, and Neatline from 1.x.x to the latest.

Run on the server/computer where the Omeka installation is found. You can pass the path to the Omeka install to the script, or it will prompt you for it.

The script can take the following flags/switches/options

    -d      Skip making a zip copy of the old Omeka folder
    -L      Upgrade Omeka and Neatline to the latest and greatest
            versions. (Note: "Pre-2.0 versions of Neatline can't be upgraded
            directly to version 2.2. Upgrade to version 2.0 first!")
    -m      Skip making a MySQL dump of the database
    -n [n]  Where [n] is a valid Neatline tag from
            https://github.com/scholarslab/Neatline. This will upgrade Neatline
            to the specified version number.  
    -o [n]  Where [n] is a valid Omeka tag from https://github.com/omeka/Omeka.
            This will upgrade Omeka to the specified version number.
    -s      Do not upgrade Omeka
    -t      Do not upgrade Neatline


# Requirements/Assumptions
- MySQL is installed on the same computer on which this script is run.
- PHP is installed.
- Git is installed.


# Basic Usage:
- Download the file.
- Change execute permissions

    ```
    chmod u+x onus
    ```
- Change any default variables at the top of the file. These should be guessed
  automatically.
    - ex. paths to MySQL, PHP, and git

    <pre>
    MYSQL="/path/to/bin/mysql"
    MDUMP="/path/to/bin/mysqldump"
    MADMIN="/path/to/bin/mysqladmin"
    PHP="/path/to/bin/php"    
    </pre>
- Change one 'sed' line if needed, to work with GNU/Linux.
    - Remove the empty double quotes after -i, or add them for MacOS

    ```
    sed -i "" "80s/.*/${migrate}/" ${path}/plugins/Neatline/migrations/2.0.0/Neatline_Migration_200.php
    ```

- Run the script

    ```
    ./onus
    ```
- This will prompt for a path to the Omeka install, then upgrade Omeka and
  Neatline to the next available major release. Run the script as many times as
  needed to get to the latest version.

# Other Usage Examples
- Download the file.
- Change execute permissions
    ```
    chmod u+x onus
    ```
- Change any default variables at the top of the file
    - ex. paths to mysql, php, and git
- Upgrade Omeka and Neatline to specific versions

    ```
    ./onus -o2.2.2 -n2.3 /path/to/Omeka/install/
    ```

- Upgrade Omeka to a specific version and skip Neatline upgrade

    ```
    ./onus -o2.2.2 -t /path/to/Omeka/install/
    ```

- Upgrade Neatline to a specific version and skip Omeka upgrade

    ```
    ./onus -s -n2.3 /path/to/Omeka/install/
    ```

- Just make a backup of the database and files, and skip upgrading Omeka and Neatline.

    ```
    ./onus -s -t /path/to/Omeka/install/
    ```

- Skip the MySQL and file backup

  ```
  ./onus -dm /path/to/Omeka/install
  ```

# Example Upgrading Omeka < 2.0

The following is an example of upgrading Omeka from version 1.5.1 and Neatline from 1.0.0.

NOTE: The Neatline Exhibit maps will be broken until Omeka and Neatline are upgraded to the latest version. This script needs to be run at least four times (with interaction with the Omeka Admin website) to get to that point.

### First Run
- Run the script for the first time

    ```
    ./onus /path/to/Omeka
    ```

- Upgrades: Omeka 1.5.1 => 1.5.3 and Neatline 1.0.0 => 1.1.3
- Login to Omeka admin and upgrade all plugins.

### Second Run
- Run the script

    ```
    ./onus /path/to/Omeka
    ```
- Go to Omeka admin and upgrade the database.
- Upgrade all plugins.
- Install Neatline's sub-plugins (widgets).
- Install and switch to the Astrolabe theme.
  ```
    cd /path/to/Omeka/themes/
    git submodule add -f https://github.com/scholarslab/astrolabe.git

  ```
- Go back to the script and type 'y' and press enter to finish the script.
- NOTE: The URL for the Neatline exhibits changes from
    - http://yoursite.com/neatline-exhibit/
    - TO
    - http://yoursite.com/neatline/
- Also, the Neatline map exhibits are broken until Omeka and Neatline are upgraded all the way.

### Third Run
- Run the script

    ```
    ./onus /path/to/Omeka
    ```
- Go to Omeka admin and upgrade the database.
- Upgrade all plugins.
- Activate needed plugins.
- NOTE: The Neatline exhibit maps are still broken at this stage.

### Fourth Run
- Run the script

    ```
    ./onus /path/to/Omeka
    ```
- Go to Omeka admin and upgrade the database.
- Upgrade all plugins.
- Activate needed plugins.
- NOTE: The Neatline exhibit maps should be working at this stage.
- Omeka and Neatline should be up to date. 
- Tweak the new theme to match the old theme, or make a new style.


# Quick Upgrade

This example upgrades Omeka from 1.5.1 to 2.2.2 and Neatline from 1.1.3 to 2.3.0 in just two steps.

### First Run
- Run the script

    ```
    ./onus -o2.0.4 -n2.0.0 /path/to/Omeka
    ```

- Go to Omeka admin and upgrade the database.
- Upgrade all plugins.
- Install Neatline's sub-plugins (widgets).
- Install and switch to the Astrolabe theme.
  ```
    cd /path/to/Omeka/themes/
    git submodule add -f https://github.com/scholarslab/astrolabe.git

  ```
- Go back to the script and type 'y' and press enter to finish the script.
- NOTE: The URL for the neatline exhibits changes from
    - http://yoursite.com/neatline-exhibit/
    - TO
    - http://yoursite.com/neatline/
- Also, the Neatline map exhibits are broken until Omeka and Neatline are upgraded all the way.

### Second Run

- Run the script

    ```
    ./onus -o2.2.2 -n2.3.0 /path/to/Omeka
    ```
- Go to Omeka admin and upgrade the database.
- Upgrade all plugins.
- Activate needed plugins.
- NOTE: The Neatline exhibit maps should be working at this stage.
- Omeka and Neatline should be up to date. 
- Tweak the new theme to match the old theme, or make a new style.

