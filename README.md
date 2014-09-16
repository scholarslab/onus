This script runs the commands needed to upgrade Omeka from 1.5 to the latest, and Neatline from 1.x to the latest.

Run on the server/computer where the Omeka installation is found. You can pass the path to the Omeka install to the script, or it will prompt you for it.



# Usage:
- Download the file.
- Change execute permissions

    ```
    chmod u+x onus.sh
    ```
- Change any default variables at the top of the file
    # ex. paths to mysql, php, and git
- Run the script

    ```
    ./onus /path/to/Omeka/install/
    ```

