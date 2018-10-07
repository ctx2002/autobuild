# README #

# Pre Request #
1. install virtual box
2. install vagrant
3. install packer - https://www.packer.io/

### What is this repository for? ###

* Quick summary
this is a repo for build up our developer machine which use puppet language.
* Version
* [Learn Markdown](https://bitbucket.org/tutorials/markdowndemo)

### How do I get set up? ###

If running this under windows powershell, some time, the powershell
will pausing, and seems not working (no output). you should press enter key to force
powershell to show output. 


* Summary of set up
if you are under windows, open up a cmd/powershell/ or whatever command line shell under administrator mode.

go https://www.packer.io/downloads.html to downland packer, and install it.

For new Developer VM

1. shut down your existing vagrant Vm first
2. clone this repo, and you will see folder autobuild. now, cd into that folder.
3. packer build ubuntu1804.json
4. vagrant box add .\output\ubuntu-18.04.box --name="php7 ubuntu 18"
5. open puppet\environments\develop\manifests\default.pp
6. change git ssh username and password under vcsrepo section
7. php .\download_submodule.php
8. git submodule update --init --recursive
9. vagrant up --provision
10. download a copy of DB, and load it into DB server.

above command will build a fully functional vagrant box for development.

some manull steps:

ingore notics and warnings.

sometime , you will see timeout error, try run vagrant provision again.

* Configuration
* Dependencies
* Database configuration
* How to run tests
* Deployment instructions

### Contribution guidelines ###

* Writing tests
* Code review
* Other guidelines

### Who do I talk to? ###

* Repo owner or admin
* Other community or team contact
