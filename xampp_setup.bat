@echo off
set /p XAMPP_CONTAINER=*Set your new XAMPP container name:
set /p SQL_CONTAINER=*Set your already created SQL container name:
echo *EULA is accepted by default.

echo ==================================================
echo Pulling XAMP image... 
echo ================================================== 

docker pull tomsik68/xampp:latest

echo ==================================================
echo Creating container... 
echo ================================================== 

set /p choice=*"Is this the second container? (Y/N)"

if /i "%choice%"=="Y" (
    docker run -it --name %XAMPP_CONTAINER% -p 2223:22 -p 8081:80 -p 3308:3306 -d -v /c/Xampphtdocs/phpsqlserver2:/opt/lampp/htdocs tomsik68/xampp:latest
    echo Using -p 2223:22 -p 8081:80 -p 3308:3306 as SECOND CONTAINER.
) else (
    docker run -it --name %XAMPP_CONTAINER% -p 2222:22 -p 8080:80 -p 3307:3306 -d -v /c/Xampphtdocs/phpsqlserver:/opt/lampp/htdocs tomsik68/xampp:latest
    echo Using -p 2222:22 -p 8080:80 -p 3307:3306 as FIRST CONTAINER.
)

echo ==================================================
echo 1/4 -- Starting configuration... 
echo ================================================== 

docker exec -it %XAMPP_CONTAINER% /bin/bash -c "apt-get update"
docker exec -it %XAMPP_CONTAINER% /bin/bash -c "apt-get upgrade -y"
docker exec -it %XAMPP_CONTAINER% /bin/bash -c "apt-get install -y autoconf build-essential unixodbc-dev"
docker exec -it %XAMPP_CONTAINER% /bin/bash -c "/opt/lampp/bin/pecl channel-update pecl.php.net"
docker exec -it %XAMPP_CONTAINER% /bin/bash -c "/opt/lampp/bin/pecl install sqlsrv"
docker exec -it %XAMPP_CONTAINER% /bin/bash -c "/opt/lampp/bin/pecl install pdo_sqlsrv"

echo ==================================================
echo 2/4 -- Setting up Docker XAMPP... 
echo ================================================== 

docker exec -it %XAMPP_CONTAINER% /bin/bash -c "echo 'extension=sqlsrv.so' >> /opt/lampp/etc/php.ini"
docker exec -it %XAMPP_CONTAINER% /bin/bash -c "echo 'extension=sqlsrv.so' >> /opt/lampp/etc/php.ini"
docker exec -it %XAMPP_CONTAINER% /bin/bash -c "echo 'extension=pdo_sqlsrv.so' >> /opt/lampp/etc/php.ini"
docker exec -it %XAMPP_CONTAINER% /bin/bash -c "cat /opt/lampp/etc/php.ini"
docker exec -it %XAMPP_CONTAINER% /bin/bash -c "mv /opt/lampp/lib/libstdc++.so.6 libstdc++.so.6_old"

echo ==================================================
echo 3/4 -- Restarting APACHE server... 
echo ================================================== 

docker exec -it %XAMPP_CONTAINER% /bin/bash -c "/opt/lampp/lampp reloadapache"
docker exec -it %XAMPP_CONTAINER% /bin/bash -c "/opt/lampp/bin/php -m"

echo ==================================================
echo 4/4 -- Restarting LAMPP service... 
echo ================================================== 

docker exec -it %XAMPP_CONTAINER% /bin/bash -c "/opt/lampp/lampp stop"
docker exec -it %XAMPP_CONTAINER% /bin/bash -c "/opt/lampp/lampp start"

@REM echo ==================================================
@REM echo Looking for php_info file...
@REM echo ================================================== 

@REM set phpFilePath=C:\Xampphtdocs\phpsqlserver\php_info.php
@REM set phpDirPath=C:\Xampphtdocs\phpsqlserver

@REM if exist "%phpFilePath%" (
@REM     echo The file php_info.php exists at %phpFilePath%.
@REM ) else (
@REM     if not exist %phpDirPath% (
@REM         mkdir %phpDirPath%
@REM     )
@REM     (
@REM         echo <?php
@REM         echo phpinfo();
@REM         echo ?>
@REM     ) > "%phpFilePath%"
@REM     echo PHP info file created at %phpFilePath%.
@REM )

@REM set /p confirm=*Press enter to continue. 

echo ==================================================
echo Starting configuration of SQLSERVER + XAMPP... 
echo ================================================== 

docker exec -it -u root %SQL_CONTAINER% /bin/bash -c "apt-get upgrade && apt-get update && apt-get install -y net-tools && apt-get install -y iputils-ping"
docker exec -it -u root %XAMPP_CONTAINER% /bin/bash -c "apt-get upgrade && apt-get update && apt-get install -y net-tools && apt-get install -y iputils-ping"

for /f "delims=" %%i in ('docker exec -it -u root %SQL_CONTAINER% hostname -I') do set SQL_IP=%%i

echo SQL Container IP Address: %SQL_IP%

echo ==================================================
echo 1/2 Making sure both container connect with ping... 
echo ================================================== 

docker exec -it  %XAMPP_CONTAINER% /bin/bash -c "ping -c 1 %SQL_IP%" >nul 2>&1

if %errorlevel%==0 (
    echo Success: Able to ping %SQL_IP%.
) else (
    echo Failure: Unable to ping %SQL_IP%.
)

echo ==================================================
echo 2/2 Installing ODBC drivers... 
echo ================================================== 

docker exec -it  %XAMPP_CONTAINER% /bin/bash -c "apt-get update && apt-get install -y gnupg2"
docker exec -it  %XAMPP_CONTAINER% /bin/bash -c "apt-get install -y gnupg"
docker exec -it  %XAMPP_CONTAINER% /bin/bash -c "apt -y install curl"
docker exec -it  %XAMPP_CONTAINER% /bin/bash -c "apt-get install -y ca-certificates"
docker exec -it  %XAMPP_CONTAINER% /bin/bash -c "curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-archive-keyring.gpg"
docker exec -it  %XAMPP_CONTAINER% /bin/bash -c "echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/debian/10/prod buster main' | tee /etc/apt/sources.list.d/mssql-release.list"
docker exec -it  %XAMPP_CONTAINER% /bin/bash -c "apt -y update"
docker exec -it  %XAMPP_CONTAINER% /bin/bash -c "apt-get update" 
docker exec -it  %XAMPP_CONTAINER% /bin/bash -c "ACCEPT_EULA=Y apt -y install msodbcsql17 mssql-tools"
docker exec -it  %XAMPP_CONTAINER% /bin/bash -c "apt -y install unixodbc-dev"
docker exec -it  %XAMPP_CONTAINER% /bin/bash -c "apt -y install gcc g++ make autoconf libc-dev pkg-config"
docker exec -it  %XAMPP_CONTAINER% /bin/bash -c "apt -y install php-pear php-dev"

if %errorlevel% neq 0 (
    echo Error occurred during installation. Output:
    type temp_output.txt

    echo.
    echo "Do you want to clean up and retry? (Y/N)"
    set /p choice=

    if /i "%choice%"=="Y" (
        echo Performing cleanup...
        docker exec -it   %XAMPP_CONTAINER% /bin/bash -c "rm /etc/apt/sources.list.d/mssql-release.list && rm /etc/apt/sources.list.d/microsoft-prod.list && apt-get clean"
        
        echo Retrying the installation...
        docker exec -it   %XAMPP_CONTAINER% /bin/bash -c "ACCEPT_EULA=Y apt -y update"
        docker exec -it   %XAMPP_CONTAINER% /bin/bash -c "ACCEPT_EULA=Y apt -y install msodbcsql17 mssql-tools"
        
        if %errorlevel% neq 0 (
            echo Retry failed. Please check the output above for errors.
        ) else (
            echo Installation succeeded on retry.
        )
    ) else (
        echo Cleanup not performed. Exiting.
    )
) else (
    echo Installation succeeded.
)

del temp_output.txt



docker exec -it  %XAMPP_CONTAINER% /bin/bash -c "apt -y install unixodbc-dev"
docker exec -it  %XAMPP_CONTAINER% /bin/bash -c "apt -y install gcc g++ make autoconf libc-dev pkg-config"
docker exec -it  %XAMPP_CONTAINER% /bin/bash -c "apt -y install php-pear php-dev"

echo ==================================================
echo Installation succeeded. 
echo ================================================== 

echo.
echo "Do you want to continue checking the connection to a database? (Y/N)"
set /p continueChoice=

if %continueChoice%==Y (

    echo ==================================================
    echo 1/2 Creating php file to check connection... 
    echo ================================================== 
    echo Now it's time to check up the connection. 
    echo This bat will create a php file connection to the database. 
    echo Insert your credentials: 

    set /p SQL_PORT=*SQL Port, maybe 1433?: 
    set /p SQL_DATABASE=*Database name, if none use master: 
    set /p SQL_USERNAME=*Username, maybe sa?: 
    set /p SQL_PWD=*Password: 

    set connectionTryPath=C:\Xampphtdocs\phpsqlserver\connectionTry.php 
        (
            echo <?php
            echo class ConnectDB {
            echo
            echo     private $db;
            echo
            echo     public function __construct() {
            echo         $this->connectON();
            echo     }
            echo
            echo     private function connectON() {
            echo         try {
            echo             $this->db = new PDO("sqlsrv:Server=172.17.0.1,%SQP_PORT%;Database=%SQL_DATABASE%","%SQL_USERNAME%","%SQL_PASSWORD%");
            echo             $this->db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            echo             $this->consulta(); 
            echo         } catch (Exception $error) {
            echo             echo "No se pudo conectar a la DB:". $error->getMessage();
            echo         }
            echo     }
            echo     echo "Conexión establecida."
            echo     public function consulta() {
            echo         $request = $this->db->prepare("SELECT @@version");
            echo         $request->execute();
            echo         $datos = $request->fetchAll(PDO::FETCH_ASSOC);
            echo         var_dump($datos);
            echo     }
            echo }
            echo
            echo new ConnectDB();
            echo
            echo ?>
        ) > "%connectionTryPath%"
        echo PHP info file created at %connectionTryPath%.

        echo ==================================================
        echo 2/2 Running connection check... 
        echo ================================================== 
        
        php "%connectionTryPath%" > output.txt
        
        echo Result of the connection: 

        type output.txt
        del output.txt

        set /p confirm=*Press enter to continue. 

        
) else (
    echo Exiting gracefully... 
)






