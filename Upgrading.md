# Upgrading to ActiveFedora 16+

ActiveFedora 16+ is built for use with Fedora 6+.

## Changes from ActiveFedora 15

- Direct/Indirect container classes now specified in headers required by Fedora 5+
- External files supported via a Link header (see ActiveFedora::File::External)
- Versioning updated based upon Fedora's use of Memento
- Ability to restore previous versions removed

## Upgrade considerations

- You may want to turn off autoversioning in Fedora (`fcrepo.autoversioning.enabled=false`) if you edit objects frequently.
- Be sure to allocate sufficient memory (2-4 GB) to the import-export tools.
- The Fedora 4 export and Fedora 5/6 data directories have lots of files so file system operations can take a LONG time.

## Upgrading from Fedora 4 (without versions)

1. Install Java 21+
2. Download [fcrepo-import-export](https://github.com/fcrepo-exts/fcrepo-import-export/) 1.2.0 or higher.
3. Export from Fedora 4 (update --resource url to match the root of your fedora instance):
```
java -jar fcrepo-import-export-1.2.0.jar -b --dir fcrepo4.7.5_export --user fedoraAdmin:fedoraAdmin --mode export --resource http://fedora:8080/fedora/rest --binaries --membership --auditLog > importexport_`date +%Y%m%dT%H%M%S`.log 2>&1
```
4. Check that all objects were exported (uses ripgrep):
```
rg '^<(http://fedora:8080/fedora/[^#:]*)>$' -g '*.ttl' fcrepo4.7.5_export/ --no-heading -m 1 -INor '$1' | sort | uniq > subject_ids
rg '<(http://fedora:8080/fedora/[^#:]*)>.*[.;]$' -g '*.ttl' fcrepo4.7.5_export/ --no-heading -INor '$1' | sort | uniq > object_ids
comm -13 subject_ids object_ids > missing_ids
```
5. (If necessary) Restart export from missing_ids file (can also be done with remaining file if export does not finish successfully):
```
java -jar fcrepo-import-export-1.2.0.jar --dir fcrepo4.7.5_export --user fedoraAdmin:fedoraAdmin --mode export --repositoryRoot http://fedora:8080/fedora/rest --resourcesFile missing_ids --binaries --membership --auditLog > importexport_`date +%Y%m%dT%H%M%S`.log 2>&1
``` 
6. Download [fcrepo-upgrade-utils](https://github.com/fcrepo-exts/fcrepo-upgrade-utils/) 6.4.0 or higher.  (6.4.0 has not been released yet so use the [Avalon patched version](https://github.com/avalonmediasystem/fcrepo-upgrade-utils/releases/download/6.3.0-AVALON/fcrepo-upgrade-utils-6.3.0-AVALON.jar) for now.)
7. Migrate Fedora 4 export to Fedora 5:
```
java -jar fcrepo-upgrade-utils-6.3.0-AVALON.jar --input-dir fcrepo4.7.5_export --output-dir fcrepo5_export --source-version 4.7.5 --target-version 5+ > upgrade_5_`date +%Y%m%dT%H%M%S`.log 2>&1
```
8. Migrate Fedora 5 data directory to Fedora 6 (be sure that --base-uri matches --resource from the Fedora 4 export):
```
java --add-opens java.base/java.util.concurrent=ALL-UNNAMED -jar fcrepo-upgrade-utils-6.3.0-AVALON.jar --input-dir fcrepo5_export --output-dir fcrepo6_export  --source-version 5+ --target-version 6+ --base-uri http://fedora:8080/fedora/rest > upgrade_6_`date +%Y%m%dT%H%M%S`.log 2>&1
```
9. Copy Fedora 6 data directory to `fcrepo.home` and startup Fedora
This will kick off Fedora's indexing which can take hours depending on the size of your repository.  During indexing Fedora will not respond to requests.
