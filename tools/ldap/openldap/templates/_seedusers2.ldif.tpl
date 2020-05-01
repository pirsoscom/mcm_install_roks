
dn: ou=Groups,dc=local,dc=io
changetype: add
objectclass: organizationalUnit
ou: Groups

# Add People OU
dn: ou=People,dc=local,dc=io
changetype: add
objectclass: organizationalUnit
ou: People

# Add users
dn: uid=demo,ou=People,dc=local,dc=io
changetype: add
objectclass: inetOrgPerson
objectclass: organizationalPerson
objectclass: person
objectclass: top
uid: demo
displayname: demo
sn: demo
cn: demo
mail: demo@ibm.com
userpassword: P4ssw0rd!

dn: uid=dev,ou=People,dc=local,dc=io
changetype: add
objectclass: inetOrgPerson
objectclass: organizationalPerson
objectclass: person
objectclass: top
uid: dev
displayname: dev
sn: dev
cn: dev
mail: dev@ibm.com
userpassword: P4ssw0rd!

dn: uid=test,ou=People,dc=local,dc=io
changetype: add
objectclass: inetOrgPerson
objectclass: organizationalPerson
objectclass: person
objectclass: top
uid: test
displayname: test
sn: test
cn: test
mail: test@ibm.com
userpassword: P4ssw0rd!

dn: uid=prod,ou=People,dc=local,dc=io
changetype: add
objectclass: inetOrgPerson
objectclass: organizationalPerson
objectclass: person
objectclass: top
uid: prod
displayname: prod
sn: prod
cn: prod
mail: prod@ibm.com
userpassword: P4ssw0rd!

# Create user group
dn: cn=demo,ou=Groups,dc=local,dc=io
changetype: add
cn: demo
objectclass: groupOfUniqueNames
objectclass: top
owner: cn=admin,dc=local,dc=io
uniquemember: uid=demo,ou=People,dc=local,dc=io

# Create user group
dn: cn=dev,ou=Groups,dc=local,dc=io
changetype: add
cn: dev
objectclass: groupOfUniqueNames
objectclass: top
owner: cn=admin,dc=local,dc=io
uniquemember: uid=dev,ou=People,dc=local,dc=io

# Create user group
dn: cn=test,ou=Groups,dc=local,dc=io
changetype: add
cn: test
objectclass: groupOfUniqueNames
objectclass: top
owner: cn=admin,dc=local,dc=io
uniquemember: uid=test,ou=People,dc=local,dc=io

# Create user group
dn: cn=prod,ou=Groups,dc=local,dc=io
changetype: add
cn: prod
objectclass: groupOfUniqueNames
objectclass: top
owner: cn=admin,dc=local,dc=io
uniquemember: uid=prod,ou=People,dc=local,dc=io





