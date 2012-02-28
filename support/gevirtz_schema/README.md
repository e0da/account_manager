To build the Ladle-compatible LDAP schema to run the tests, you have to build
the package with Maven.

    mvn clean && mvn package

Then a .jar file is generated in target containing the add-on schema. To use it
with Ladle, you might

    ldif = File.expand_path '../../../config/test.ldif', __FILE__
    jar = File.expand_path '../../../support/gevirtz_schema/target/gevirtz-schema-1.0-SNAPSHOT.jar', __FILE__
    opts = {
      quiet: true,
      tmpdir: 'tmp',
      ldif: ldif,
      additional_classpath: jar,
      custom_schemas: 'edu.ucsb.education.account.GevirtzSchema'
    }
    Ladle::Server.new(opts).start
