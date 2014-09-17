This script runs the commands needed to upgrade Omeka from 1.5 to the latest, and Neatline from 1.x to the latest.

Run on the server/computer where the Omeka installation is found. You can pass the path to the Omeka install to the script, or it will prompt you for it.



# Usage:
- Download the file.
- Change execute permissions

    ```
    chmod u+x onus.sh
    ```
- Change any default variables at the top of the file
    - ex. paths to mysql, php, and git
- Run the script

    ```
    ./onus.sh /path/to/Omeka/install/
    ```


# Example:

An example usage, upgrading Omeka from version 1.5.1 and Neatline from 1.0.0.

NOTE: The Neatline Exhibit maps will be broken until Omeka and Neatline are upgraded to the latest version. This script needs to be run at least four times (with interaction with the Omeka Admin website) to get to that point.

### First Run
- Run the script for the first time

    ```
    ./onus.sh /path/to/Omeka
    ```

- Upgrades: Omeka 1.5.1 => 1.5.3 and Neatline 1.0.0 => 1.1.3
- Login to Omeka admin and upgrade all plugins.

### Second Run
- Run the script

    ```
    ./onus.sh /path/to/Omeka
    ```
- Go to Omeka admin and upgrade the database.
- Upgrade all plugins.
- Install Neatline's sub-plugins (widgets).
- Switch to the Astrolabe theme.
- Go back to the script and type 'y' and press enter to finish the script.
- NOTE: The URL for the neatline exhibits changes from
    - http://yoursite.com/neatline-exhibit/
    - TO
    - http://yoursite.com/neatline/
- Also, the neatline map exhibits are broken until Omeka and Neatline are upgraded all the way.

### Third Run
- Run the script

    ```
    ./onus.sh /path/to/Omeka
    ```
- Go to Omeka admin and upgrade the database.
- Upgrade all plugins.
- Activate needed plugins.
- NOTE: The neatline exhibit maps are still broken at this stage.

### Fourth Run
- Run the script

    ```
    ./onus.sh /path/to/Omeka
    ```
- Go to Omeka admin and upgrade the database.
- Upgrade all plugins.
- Activate needed plugins.
- NOTE: The neatline exhibit maps should be working at this stage.
- Omeka and Neatline should be up to date. 
- Tweak the new theme to match the old theme, or make a new style.



