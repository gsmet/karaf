@echo off
rem
rem
rem    Licensed to the Apache Software Foundation (ASF) under one or more
rem    contributor license agreements.  See the NOTICE file distributed with
rem    this work for additional information regarding copyright ownership.
rem    The ASF licenses this file to You under the Apache License, Version 2.0
rem    (the "License"); you may not use this file except in compliance with
rem    the License.  You may obtain a copy of the License at
rem
rem       http://www.apache.org/licenses/LICENSE-2.0
rem
rem    Unless required by applicable law or agreed to in writing, software
rem    distributed under the License is distributed on an "AS IS" BASIS,
rem    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
rem    See the License for the specific language governing permissions and
rem    limitations under the License.
rem
rem 
rem $Id: karaf.bat 979 2005-11-30 22:50:55Z bsnyder $
rem 

if not "%ECHO%" == "" echo %ECHO%

setlocal
set DIRNAME=%~dp0%
set PROGNAME=%~nx0%
set ARGS=%*

title Karaf

goto BEGIN

:warn
    echo %PROGNAME%: %*
goto :EOF

:BEGIN

rem # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if not "%KARAF_HOME%" == "" (
    call :warn Ignoring predefined value for KARAF_HOME
)
set KARAF_HOME=%DIRNAME%..
if not exist "%KARAF_HOME%" (
    call :warn KARAF_HOME is not valid: %KARAF_HOME%
    goto END
)

if not "%KARAF_BASE%" == "" (
    if not exist "%KARAF_BASE%" (
       call :warn KARAF_BASE is not valid: %KARAF_BASE%
       goto END
    )
)
if "%KARAF_BASE%" == "" (
  set KARAF_BASE=%KARAF_HOME%
)

set LOCAL_CLASSPATH=%CLASSPATH%
set DEFAULT_JAVA_OPTS=-server -Xmx512M -Dderby.system.home="%KARAF_BASE%\data\derby" -Dderby.storage.fileSyncTransactionLog=true -Dcom.sun.management.jmxremote
set CLASSPATH=%LOCAL_CLASSPATH%;%KARAF_BASE%\conf
set DEFAULT_JAVA_DEBUG_OPTS=-Xdebug -Xnoagent -Djava.compiler=NONE -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=5005

if "%LOCAL_CLASSPATH%" == "" goto :KARAF_CLASSPATH_EMPTY
    set CLASSPATH=%LOCAL_CLASSPATH%;%KARAF_BASE%\conf
    goto :KARAF_CLASSPATH_END
:KARAF_CLASSPATH_EMPTY
    set CLASSPATH=%KARAF_BASE%\conf
:KARAF_CLASSPATH_END

rem Setup Karaf Home
if exist "%KARAF_HOME%\conf\karaf-rc.cmd" call %KARAF_HOME%\conf\karaf-rc.cmd
if exist "%HOME%\karaf-rc.cmd" call %HOME%\karaf-rc.cmd

rem Support for loading native libraries
set PATH=%PATH%;%KARAF_BASE%\lib;%KARAF_HOME%\lib

rem Setup the Java Virtual Machine
if not "%JAVA%" == "" goto :Check_JAVA_END
    set JAVA=java
    if "%JAVA_HOME%" == "" call :warn JAVA_HOME not set; results may vary
    if not "%JAVA_HOME%" == "" set JAVA=%JAVA_HOME%\bin\java
    if not exist "%JAVA_HOME%" (
        call :warn JAVA_HOME is not valid: "%JAVA_HOME%"
        goto END
    )
:Check_JAVA_END

if "%JAVA_OPTS%" == "" set JAVA_OPTS=%DEFAULT_JAVA_OPTS%

if "%KARAF_DEBUG%" == "" goto :KARAF_DEBUG_END
    rem Use the defaults if JAVA_DEBUG_OPTS was not set
    if "%JAVA_DEBUG_OPTS%" == "" set JAVA_DEBUG_OPTS=%DEFAULT_JAVA_DEBUG_OPTS%
    
    set "JAVA_OPTS=%JAVA_DEBUG_OPTS% %JAVA_OPTS%"
    call :warn Enabling Java debug options: %JAVA_DEBUG_OPTS%
:KARAF_DEBUG_END

if "%KARAF_PROFILER%" == "" goto :KARAF_PROFILER_END
    set KARAF_PROFILER_SCRIPT=%KARAF_HOME%\conf\profiler\%KARAF_PROFILER%.cmd
    
    if exist "%KARAF_PROFILER_SCRIPT%" goto :KARAF_PROFILER_END
    call :warn Missing configuration for profiler '%KARAF_PROFILER%': %KARAF_PROFILER_SCRIPT%
    goto END
:KARAF_PROFILER_END

rem Setup the classpath
pushd "%KARAF_HOME%\lib"
for %%G in (*.*) do call:APPEND_TO_CLASSPATH %%G
popd
goto CLASSPATH_END

: APPEND_TO_CLASSPATH
set filename=%~1
set suffix=%filename:~-4%
if %suffix% equ .jar set CLASSPATH=%CLASSPATH%;%KARAF_HOME%\lib\%filename%
goto :EOF

:CLASSPATH_END

rem Execute the JVM or the load the profiler
if "%KARAF_PROFILER%" == "" goto :RUN
    rem Execute the profiler if it has been configured
    call :warn Loading profiler script: %KARAF_PROFILER_SCRIPT%
    call %KARAF_PROFILER_SCRIPT%

:RUN
    SET OPTS=-Dkaraf.startLocalConsole=true -Dkaraf.startRemoteShell=true
    SET SHIFT=false
    if "%1" == "console" goto :EXECUTE_CONSOLE
    if "%1" == "server" goto :EXECUTE_SERVER
    if "%1" == "client" goto :EXECUTE_CLIENT
    goto :EXECUTE

:EXECUTE_CONSOLE
    SET SHIFT=true
    goto :EXECUTE    

:EXECUTE_SERVER
    SET OPTS="-Dkaraf.startLocalConsole=false -Dkaraf.startRemoteShell=true"
    SET SHIFT=true
    goto :EXECUTE

:EXECUTE_CLIENT
    SET OPTS="-Dkaraf.startLocalConsole=true -Dkaraf.startRemoteShell=false"
    SET SHIFT=true
    goto :EXECUTE

:EXECUTE
    if "%SHIFT%" == "true" SET ARGS=%2 %3 %4 %5 %6 %7 %8
    if not "%SHIFT%" == "true" SET ARGS=%1 %2 %3 %4 %5 %6 %7 %8    
    rem Execute the Java Virtual Machine
    "%JAVA%" %JAVA_OPTS% %OPTS% -classpath "%CLASSPATH%" -Dkaraf.home="%KARAF_HOME%" -Dkaraf.base="%KARAF_BASE%" -Djava.util.logging.config.file=%KARAF_BASE%\etc\java.util.logging.properties org.apache.felix.karaf.main.Main %ARGS%

rem # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

:END

endlocal

if not "%PAUSE%" == "" pause

:END_NO_PAUSE

