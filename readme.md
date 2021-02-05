# Containerization of Chemaxon JChem Postgres Cartridge

This is my attempt to fix [the sample provided by chemaxon](https://github.com/ChemAxon/jpc-docker). Things made better:

- based on Debian 10 Buster (slim)
- Bump to Postgres 12
- Bump to Open JDK 11 (headless installation)
- Support for JPC 5+
- No initialization during build of the image. The `Dockerfile` respects `POSTGRES_USER` and `POSTGRES_PASSWORD` provided via environment _**on startup**_ and creates a user and a database at first start, not earlier.

### Getting started
- download JPC 5+ Debian/Ubuntu package (`jchem-psql_<version>_amd64.deb`) from Chemaxon's [download page](https://chemaxon.com/download/jchem-suite/#jpc) (you'll need a login)
- copy the downloaded file next to the `Dockerfile` and name it `jchem-psql_amd64.deb`
- copy your `license.cxl` next to the `Dockerfile`
- build your container image: `docker build -t jpc:latest .`
- run a container from the built image: `docker run -e POSTGRES_USER=jpcuser -e POSTGRES_PASSWORD=banana -p 5432:5432 jpc:latest`

### try it out
- connect to the database from a shell (with postgres-client installed) `psql -h localhost -p 5432 -U jpcuser`
- run some cartridge commands:

```
jpcuser=# CREATE table test(mol Molecule("sample"), id int);
CREATE TABLE

jpcuser=# insert into test(id, mol) values (1, 'c'), (2, 'cc'), (3, 'ccc');
INSERT 0 3

jpcuser=# select * from test;
 mol | id 
-----+----
 c   |  1
 cc  |  2
 ccc |  3
(3 rows)

jpcuser=# select * from test where mol |<| 'cc';
 mol | id 
-----+----
 c   |  1
 cc  |  2
(2 rows)
```

### todo's

- [ ] clean shutdown. The postgres process get's killed on stop which might lead to data corruption
- [ ] support volumes for data and molecule types
- [ ] uncomment `set -Eeo pipefail` on `entrypoint.sh`. for some reason there is still a stderr output when PC start that lets the script fail