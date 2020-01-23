# Changelog

## [v13.1.2](https://github.com/samvera/active_fedora/tree/HEAD) (2020-01-23)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v13.1.1...v13.1.2)

**Closed issues:**

- Add support for Rails 6.0.z releases [\#1411](https://github.com/samvera/active_fedora/issues/1411)
- Add support for Ruby 2.7.z releases [\#1410](https://github.com/samvera/active_fedora/issues/1410)

**Merged pull requests:**

- Prepare for release [\#1414](https://github.com/samvera/active_fedora/pull/1414) ([cjcolvar](https://github.com/cjcolvar))
- Always rewind IO content even when the file is new. [\#1413](https://github.com/samvera/active_fedora/pull/1413) ([cjcolvar](https://github.com/cjcolvar))
- Adding Ruby 2.7 and updating the existing Ruby and Rails releases on the CircleCI config. [\#1412](https://github.com/samvera/active_fedora/pull/1412) ([jrgriffiniii](https://github.com/jrgriffiniii))

## [v13.1.1](https://github.com/samvera/active_fedora/tree/v13.1.1) (2019-10-01)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v13.1.0...v13.1.1)

**Merged pull requests:**

- Upgrades the dependency for faraday-encoding in order to ensure that FrozenError is not raised for HTTP request body content; Releases 13.1.1 [\#1409](https://github.com/samvera/active_fedora/pull/1409) ([jrgriffiniii](https://github.com/jrgriffiniii))

## [v13.1.0](https://github.com/samvera/active_fedora/tree/v13.1.0) (2019-09-18)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v13.0.0...v13.1.0)

## [v13.0.0](https://github.com/samvera/active_fedora/tree/v13.0.0) (2019-08-19)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v12.2.0...v13.0.0)

## [v12.2.0](https://github.com/samvera/active_fedora/tree/v12.2.0) (2019-08-16)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v12.1.1...v12.2.0)

**Implemented enhancements:**

- Test against Rails release 5.1.7, along with Ruby releases 2.6.3, 2.5.5, and 2.4.6 [\#1386](https://github.com/samvera/active_fedora/issues/1386)

## [v12.1.1](https://github.com/samvera/active_fedora/tree/v12.1.1) (2019-04-03)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v12.1.0...v12.1.1)

**Closed issues:**

- Solr config refers to deprecated LatLonType [\#1370](https://github.com/samvera/active_fedora/issues/1370)

## [v12.1.0](https://github.com/samvera/active_fedora/tree/v12.1.0) (2019-02-28)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v8.7.0...v12.1.0)

## [v8.7.0](https://github.com/samvera/active_fedora/tree/v8.7.0) (2018-12-11)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v8.6.0...v8.7.0)

**Merged pull requests:**

- Prepare release 13.1.0 [\#1408](https://github.com/samvera/active_fedora/pull/1408) ([no-reply](https://github.com/no-reply))
- Deprecate `\#clear\_changed\_attributes` [\#1407](https://github.com/samvera/active_fedora/pull/1407) ([no-reply](https://github.com/no-reply))
- Readd support for Ruby 2.4.7 [\#1404](https://github.com/samvera/active_fedora/pull/1404) ([no-reply](https://github.com/no-reply))
- Rails 6 [\#1403](https://github.com/samvera/active_fedora/pull/1403) ([no-reply](https://github.com/no-reply))
- Force overwrite of `solr/conf` files if they have changes [\#1400](https://github.com/samvera/active_fedora/pull/1400) ([no-reply](https://github.com/no-reply))
- Releases version 13.0.0 [\#1399](https://github.com/samvera/active_fedora/pull/1399) ([jrgriffiniii](https://github.com/jrgriffiniii))
- Update CircleCI Ruby and Rails versions [\#1390](https://github.com/samvera/active_fedora/pull/1390) ([botimer](https://github.com/botimer))
- Updates the CircleCI configuration to test against Rails release 5.1.7, along with Ruby releases 2.6.3, 2.5.5, and 2.4.6 [\#1387](https://github.com/samvera/active_fedora/pull/1387) ([jrgriffiniii](https://github.com/jrgriffiniii))
- Releases version 12.2.0 [\#1385](https://github.com/samvera/active_fedora/pull/1385) ([jrgriffiniii](https://github.com/jrgriffiniii))
- Removes the dependency for solrizer [\#1384](https://github.com/samvera/active_fedora/pull/1384) ([jrgriffiniii](https://github.com/jrgriffiniii))
- Adds support for Float value indexing and ensures that Solrizer errors are defined within the global namespace [\#1383](https://github.com/samvera/active_fedora/pull/1383) ([jrgriffiniii](https://github.com/jrgriffiniii))
- Prep for 12.1.1 release [\#1382](https://github.com/samvera/active_fedora/pull/1382) ([bess](https://github.com/bess))
- Remove deprecated Solr StandardFilter [\#1380](https://github.com/samvera/active_fedora/pull/1380) ([bess](https://github.com/bess))
- Use samvera orb [\#1379](https://github.com/samvera/active_fedora/pull/1379) ([cjcolvar](https://github.com/cjcolvar))
- Pin the version of rails that is used [\#1377](https://github.com/samvera/active_fedora/pull/1377) ([jcoyne](https://github.com/jcoyne))
- Remove references to `LatLonType` from Solr schema [\#1376](https://github.com/samvera/active_fedora/pull/1376) ([no-reply](https://github.com/no-reply))
- Add and test Ruby 2.6.0 [\#1375](https://github.com/samvera/active_fedora/pull/1375) ([no-reply](https://github.com/no-reply))
- Use PointField Solr types rather than deprecated Trie\* types [\#1368](https://github.com/samvera/active_fedora/pull/1368) ([jcoyne](https://github.com/jcoyne))
- Limit support to Rails 5.2; add support for `ldp` 1.0 [\#1366](https://github.com/samvera/active_fedora/pull/1366) ([no-reply](https://github.com/no-reply))
- Prepare release 12.1.0 [\#1365](https://github.com/samvera/active_fedora/pull/1365) ([no-reply](https://github.com/no-reply))
- Clarify support in build matrix [\#1364](https://github.com/samvera/active_fedora/pull/1364) ([no-reply](https://github.com/no-reply))
- Fix `\#blank?` and `\#present?` [\#1361](https://github.com/samvera/active_fedora/pull/1361) ([no-reply](https://github.com/no-reply))
- Link TODOs to recorded issues [\#1359](https://github.com/samvera/active_fedora/pull/1359) ([botimer](https://github.com/botimer))
- Maintenance templates [\#1356](https://github.com/samvera/active_fedora/pull/1356) ([barmintor](https://github.com/barmintor))
- Implement enumeration for `Relation\#each` [\#1348](https://github.com/samvera/active_fedora/pull/1348) ([no-reply](https://github.com/no-reply))
- Removing remaining references to the projecthydra GitHub organization in the code base [\#1328](https://github.com/samvera/active_fedora/pull/1328) ([jrgriffiniii](https://github.com/jrgriffiniii))
- Adding the Coveralls badge and restructuring spec helper for Coveralls reporting [\#1326](https://github.com/samvera/active_fedora/pull/1326) ([jrgriffiniii](https://github.com/jrgriffiniii))
- Updating CONTRIBUTING with references to Samvera [\#1325](https://github.com/samvera/active_fedora/pull/1325) ([jrgriffiniii](https://github.com/jrgriffiniii))
- Resolve \#1321; Remove Gemnasium badge [\#1324](https://github.com/samvera/active_fedora/pull/1324) ([botimer](https://github.com/botimer))
- Allow faraday 0.15 [\#1323](https://github.com/samvera/active_fedora/pull/1323) ([jcoyne](https://github.com/jcoyne))
- Run and test validation callbacks [\#1322](https://github.com/samvera/active_fedora/pull/1322) ([cjcolvar](https://github.com/cjcolvar))
- Update rubocop to 0.56.0 [\#1313](https://github.com/samvera/active_fedora/pull/1313) ([jcoyne](https://github.com/jcoyne))
- Fix support for Rails 5.2 [\#1312](https://github.com/samvera/active_fedora/pull/1312) ([cjcolvar](https://github.com/cjcolvar))
- suggest searchComponent and requestHandler disabled by default [\#1311](https://github.com/samvera/active_fedora/pull/1311) ([cjcolvar](https://github.com/cjcolvar))
- Add Solr dateRange field type and dynamic fields to schema.xml [\#1304](https://github.com/samvera/active_fedora/pull/1304) ([cjcolvar](https://github.com/cjcolvar))
- Request ntriples when fetching descendants to avoid timeout issues [\#1300](https://github.com/samvera/active_fedora/pull/1300) ([cjcolvar](https://github.com/cjcolvar))
- Allow for a pluggable minter service [\#1295](https://github.com/samvera/active_fedora/pull/1295) ([jcoyne](https://github.com/jcoyne))
- Rename solr/config directory to solr/conf [\#1294](https://github.com/samvera/active_fedora/pull/1294) ([jcoyne](https://github.com/jcoyne))
- Adding update\_index callback hooks [\#1282](https://github.com/samvera/active_fedora/pull/1282) ([jeremyf](https://github.com/jeremyf))

## [v8.6.0](https://github.com/samvera/active_fedora/tree/v8.6.0) (2018-12-10)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v11.5.4...v8.6.0)

**Closed issues:**

- Trie\* Solr fields are deprecated [\#1367](https://github.com/samvera/active_fedora/issues/1367)
- Release ActiveFedora 12.0.2 [\#1306](https://github.com/samvera/active_fedora/issues/1306)

**Merged pull requests:**

- Add a helpful error when the has\_model\_ssim is missing [\#1373](https://github.com/samvera/active_fedora/pull/1373) ([jcoyne](https://github.com/jcoyne))
- Add has\_model so that the indexed value can be overridden [\#1371](https://github.com/samvera/active_fedora/pull/1371) ([jcoyne](https://github.com/jcoyne))

## [v11.5.4](https://github.com/samvera/active_fedora/tree/v11.5.4) (2018-09-24)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v11.5.3...v11.5.4)

**Merged pull requests:**

- Bump version to 11.5.4 [\#1363](https://github.com/samvera/active_fedora/pull/1363) ([no-reply](https://github.com/no-reply))
- \[backport\] Fix `\#blank?` and `\#present?` [\#1362](https://github.com/samvera/active_fedora/pull/1362) ([no-reply](https://github.com/no-reply))

## [v11.5.3](https://github.com/samvera/active_fedora/tree/v11.5.3) (2018-09-22)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v12.0.2...v11.5.3)

**Merged pull requests:**

-  Prepare release 11.5.3 [\#1360](https://github.com/samvera/active_fedora/pull/1360) ([no-reply](https://github.com/no-reply))
- Pin to Rails 5.1 [\#1355](https://github.com/samvera/active_fedora/pull/1355) ([no-reply](https://github.com/no-reply))
- Implement enumeration for `Relation\#each` [\#1353](https://github.com/samvera/active_fedora/pull/1353) ([no-reply](https://github.com/no-reply))

## [v12.0.2](https://github.com/samvera/active_fedora/tree/v12.0.2) (2018-09-21)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v8.5.0...v12.0.2)

**Closed issues:**

- Update README/Code\_of\_Conduct/CONTRIBUTING/etc to CCMWG Templates [\#1349](https://github.com/samvera/active_fedora/issues/1349)
- Remove Gemnasium from README [\#1321](https://github.com/samvera/active_fedora/issues/1321)
- Confirm copyright statement/years [\#1320](https://github.com/samvera/active_fedora/issues/1320)
- Convert TODO comments to issues [\#1319](https://github.com/samvera/active_fedora/issues/1319)
- Change Rubygems Homepage to Samvera org [\#1318](https://github.com/samvera/active_fedora/issues/1318)
- Clean up references to Hydra / Samvera [\#1317](https://github.com/samvera/active_fedora/issues/1317)
- Report coverage to Coveralls [\#1316](https://github.com/samvera/active_fedora/issues/1316)
- ActiveFedora.clean! should delete permission template entries from the database [\#1314](https://github.com/samvera/active_fedora/issues/1314)

**Merged pull requests:**

- Bump version of solr\_wrapper to get around failed download of solr and fix travis build [\#1357](https://github.com/samvera/active_fedora/pull/1357) ([no-reply](https://github.com/no-reply))
- Pin to Rails 5.1 [\#1351](https://github.com/samvera/active_fedora/pull/1351) ([no-reply](https://github.com/no-reply))
- Bump version to 12.0.2 [\#1350](https://github.com/samvera/active_fedora/pull/1350) ([no-reply](https://github.com/no-reply))

## [v8.5.0](https://github.com/samvera/active_fedora/tree/v8.5.0) (2018-04-26)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v8.4.2...v8.5.0)

**Merged pull requests:**

- Add compatibility with Rubydora 2.1; drop support for Rails \<= 4.2.9 [\#1310](https://github.com/samvera/active_fedora/pull/1310) ([cbeer](https://github.com/cbeer))

## [v8.4.2](https://github.com/samvera/active_fedora/tree/v8.4.2) (2018-03-13)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v12.0.1...v8.4.2)

**Merged pull requests:**

- Prefer om\_term\_values to send when solrizing within SimpleDatastream [\#1302](https://github.com/samvera/active_fedora/pull/1302) ([mjgiarlo](https://github.com/mjgiarlo))

## [v12.0.1](https://github.com/samvera/active_fedora/tree/v12.0.1) (2018-01-12)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v11.5.2...v12.0.1)

**Merged pull requests:**

- Restore equivalent\_class? method [\#1298](https://github.com/samvera/active_fedora/pull/1298) ([jcoyne](https://github.com/jcoyne))
- Overwrite the .solr\_wrapper.yml provided by blacklight [\#1293](https://github.com/samvera/active_fedora/pull/1293) ([jcoyne](https://github.com/jcoyne))

## [v11.5.2](https://github.com/samvera/active_fedora/tree/v11.5.2) (2017-11-08)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v11.5.1...v11.5.2)

**Merged pull requests:**

- Treat resources as allowable single valued properties [\#1290](https://github.com/samvera/active_fedora/pull/1290) ([no-reply](https://github.com/no-reply))

## [v11.5.1](https://github.com/samvera/active_fedora/tree/v11.5.1) (2017-11-08)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v12.0.0...v11.5.1)

**Merged pull requests:**

- Backports [\#1289](https://github.com/samvera/active_fedora/pull/1289) ([no-reply](https://github.com/no-reply))

## [v12.0.0](https://github.com/samvera/active_fedora/tree/v12.0.0) (2017-11-07)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v11.5.0...v12.0.0)

**Merged pull requests:**

- Prepare release 12.0.0 [\#1288](https://github.com/samvera/active_fedora/pull/1288) ([no-reply](https://github.com/no-reply))
- Add support for ActiveTriples 1.0.0 [\#1287](https://github.com/samvera/active_fedora/pull/1287) ([no-reply](https://github.com/no-reply))
- Treat `RDF::Term` implementers as singular values [\#1286](https://github.com/samvera/active_fedora/pull/1286) ([no-reply](https://github.com/no-reply))
- Allow SolrService to submit queries via HTTP POST [\#1283](https://github.com/samvera/active_fedora/pull/1283) ([mjgiarlo](https://github.com/mjgiarlo))
- Add an IO like object for Fedora files [\#1281](https://github.com/samvera/active_fedora/pull/1281) ([ojlyytinen](https://github.com/ojlyytinen))
- Remove deprecated defaultOperator and defaultSearchField solr configs [\#1280](https://github.com/samvera/active_fedora/pull/1280) ([geekscruff](https://github.com/geekscruff))
- Make the comment reflect the correct wrapper [\#1279](https://github.com/samvera/active_fedora/pull/1279) ([mark-dce](https://github.com/mark-dce))
- Prevent `exists?` from throwing exceptions [\#1277](https://github.com/samvera/active_fedora/pull/1277) ([atz](https://github.com/atz))
- Allow the descendant fetcher to be more flexible by grouping uris by model [\#1275](https://github.com/samvera/active_fedora/pull/1275) ([cjcolvar](https://github.com/cjcolvar))
- Rescue ObjectNotFoundError in find\_each [\#1273](https://github.com/samvera/active_fedora/pull/1273) ([hackmastera](https://github.com/hackmastera))
- Request options allow for setting timeout of Fedora client [\#1271](https://github.com/samvera/active_fedora/pull/1271) ([cjcolvar](https://github.com/cjcolvar))
- Change Hydra to Samvera [\#1265](https://github.com/samvera/active_fedora/pull/1265) ([jcoyne](https://github.com/jcoyne))
- Allow access to ETag with `AF::Common\#etag` [\#1263](https://github.com/samvera/active_fedora/pull/1263) ([no-reply](https://github.com/no-reply))
- Bump version to 12.0.0.alpha [\#1262](https://github.com/samvera/active_fedora/pull/1262) ([jcoyne](https://github.com/jcoyne))
- Call get instead of HEAD + GET [\#1261](https://github.com/samvera/active_fedora/pull/1261) ([jcoyne](https://github.com/jcoyne))
- Set the proper string encoding on responses [\#1259](https://github.com/samvera/active_fedora/pull/1259) ([jcoyne](https://github.com/jcoyne))
- No need to set RSolr 2.0 explicitly [\#1257](https://github.com/samvera/active_fedora/pull/1257) ([jcoyne](https://github.com/jcoyne))
- Bump LDP version to ~\> 0.7.0 [\#1255](https://github.com/samvera/active_fedora/pull/1255) ([jcoyne](https://github.com/jcoyne))
- Bump rspec requirement to ~\>3.5 [\#1253](https://github.com/samvera/active_fedora/pull/1253) ([atz](https://github.com/atz))
- File metadata should have a modified\_date [\#1252](https://github.com/samvera/active_fedora/pull/1252) ([cjcolvar](https://github.com/cjcolvar))
- Make solr.yml consistent w/ blacklight.yml \(and itself\) [\#1249](https://github.com/samvera/active_fedora/pull/1249) ([atz](https://github.com/atz))
- Instrument uncached fetches [\#1248](https://github.com/samvera/active_fedora/pull/1248) ([jcoyne](https://github.com/jcoyne))
- Merge Solrizer into ActiveFedora [\#1223](https://github.com/samvera/active_fedora/pull/1223) ([jcoyne](https://github.com/jcoyne))

## [v11.5.0](https://github.com/samvera/active_fedora/tree/v11.5.0) (2017-10-12)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v11.4.1...v11.5.0)

**Closed issues:**

- AF::SolrService.query should permit HTTP POST [\#399](https://github.com/samvera/active_fedora/issues/399)

**Merged pull requests:**

- Allow SolrService to submit queries via HTTP POST [\#1284](https://github.com/samvera/active_fedora/pull/1284) ([mjgiarlo](https://github.com/mjgiarlo))

## [v11.4.1](https://github.com/samvera/active_fedora/tree/v11.4.1) (2017-10-04)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v8.4.1...v11.4.1)

**Implemented enhancements:**

- Connection should support timeout option [\#1105](https://github.com/samvera/active_fedora/issues/1105)

**Fixed bugs:**

- exists? throws exception on class mismatch instead of returning false [\#1276](https://github.com/samvera/active_fedora/issues/1276)

## [v8.4.1](https://github.com/samvera/active_fedora/tree/v8.4.1) (2017-07-12)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v11.4.0...v8.4.1)

**Merged pull requests:**

- Fix AF compatibility with ruby 2.4 [\#1270](https://github.com/samvera/active_fedora/pull/1270) ([cbeer](https://github.com/cbeer))

## [v11.4.0](https://github.com/samvera/active_fedora/tree/v11.4.0) (2017-06-28)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v11.3.1...v11.4.0)

**Merged pull requests:**

- \[backport\] Allow access to ETag with `AF::Common\#etag` [\#1266](https://github.com/samvera/active_fedora/pull/1266) ([jcoyne](https://github.com/jcoyne))
- \[backport\] Call get instead of HEAD + GET [\#1264](https://github.com/samvera/active_fedora/pull/1264) ([jcoyne](https://github.com/jcoyne))

## [v11.3.1](https://github.com/samvera/active_fedora/tree/v11.3.1) (2017-06-15)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v11.3.0...v11.3.1)

**Closed issues:**

- Text files read from fedora do not have encoding set. [\#1258](https://github.com/samvera/active_fedora/issues/1258)
- ActiveFedora::Base.first fails by assuming id=1 [\#1254](https://github.com/samvera/active_fedora/issues/1254)

**Merged pull requests:**

- Set the proper string encoding on responses [\#1260](https://github.com/samvera/active_fedora/pull/1260) ([jcoyne](https://github.com/jcoyne))

## [v11.3.0](https://github.com/samvera/active_fedora/tree/v11.3.0) (2017-06-13)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v11.2.0...v11.3.0)

**Implemented enhancements:**

- AF::Base initialization should not require a FCR4 connection [\#1060](https://github.com/samvera/active_fedora/issues/1060)

**Closed issues:**

- rake spec fails with `undefined method shared\_context\_metadata\_behavior=...` [\#1229](https://github.com/samvera/active_fedora/issues/1229)
- README instructions for test solr\_wrapper wrong [\#1216](https://github.com/samvera/active_fedora/issues/1216)
- Calling ActiveFedora.fedora.user should not connect to the repository. [\#880](https://github.com/samvera/active_fedora/issues/880)
- \<\< on properties doesn't persist [\#768](https://github.com/samvera/active_fedora/issues/768)
- Optimize reads [\#463](https://github.com/samvera/active_fedora/issues/463)
- RDF wiki, lesson 2 should use datastreams [\#359](https://github.com/samvera/active_fedora/issues/359)

**Merged pull requests:**

- Bump LDP version to ~\> 0.7.0 [\#1256](https://github.com/samvera/active_fedora/pull/1256) ([jcoyne](https://github.com/jcoyne))

## [v11.2.0](https://github.com/samvera/active_fedora/tree/v11.2.0) (2017-05-18)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v11.1.6...v11.2.0)

**Closed issues:**

- Unknown attribute: \_attributes [\#1237](https://github.com/samvera/active_fedora/issues/1237)

**Merged pull requests:**

- Update travis build matrix [\#1243](https://github.com/samvera/active_fedora/pull/1243) ([cbeer](https://github.com/cbeer))
- Release 11.2.0 [\#1242](https://github.com/samvera/active_fedora/pull/1242) ([dazza-codes](https://github.com/dazza-codes))
- Expose solr connection options as an attribute [\#1241](https://github.com/samvera/active_fedora/pull/1241) ([cbeer](https://github.com/cbeer))
- YAML.safe\_load - allow YAML aliases - loading solr.yml and fedora.yml [\#1240](https://github.com/samvera/active_fedora/pull/1240) ([dazza-codes](https://github.com/dazza-codes))
- more powerful ActiveFedora::FixityService [\#1239](https://github.com/samvera/active_fedora/pull/1239) ([jrochkind](https://github.com/jrochkind))
- Metadata node save [\#1235](https://github.com/samvera/active_fedora/pull/1235) ([cjcolvar](https://github.com/cjcolvar))
- Pass nil instead of a nil RDF::URI as subject to Ldp::Resource to avoid head request [\#1233](https://github.com/samvera/active_fedora/pull/1233) ([cjcolvar](https://github.com/cjcolvar))
- Raise expected RuntimeError by using correct variable [\#1232](https://github.com/samvera/active_fedora/pull/1232) ([cjcolvar](https://github.com/cjcolvar))
- Pass the index\_config to the RDF::IndexingService [\#1231](https://github.com/samvera/active_fedora/pull/1231) ([jcoyne](https://github.com/jcoyne))
- Fix 1219 [\#1230](https://github.com/samvera/active_fedora/pull/1230) ([barmintor](https://github.com/barmintor))
- Add Indexing::Map\#merge [\#1227](https://github.com/samvera/active_fedora/pull/1227) ([jcoyne](https://github.com/jcoyne))
- Don't shadow attr\_accessor with custom accessor method [\#1226](https://github.com/samvera/active_fedora/pull/1226) ([jcoyne](https://github.com/jcoyne))
- Indexing::Map::IndexObject takes behaviors as a parameter [\#1225](https://github.com/samvera/active_fedora/pull/1225) ([jcoyne](https://github.com/jcoyne))
- Update documentation [\#1224](https://github.com/samvera/active_fedora/pull/1224) ([jcoyne](https://github.com/jcoyne))
- Indexing\#descendant\_uris capable of prioritizing at front of list [\#1219](https://github.com/samvera/active_fedora/pull/1219) ([jrochkind](https://github.com/jrochkind))
- \#reindex\_everything improvements [\#1218](https://github.com/samvera/active_fedora/pull/1218) ([jrochkind](https://github.com/jrochkind))
- Update rspec descriptions to avoid "should" [\#1217](https://github.com/samvera/active_fedora/pull/1217) ([jcoyne](https://github.com/jcoyne))

## [v11.1.6](https://github.com/samvera/active_fedora/tree/v11.1.6) (2017-04-19)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v11.1.5...v11.1.6)

**Merged pull requests:**

- Update fcrepo\_wrapper command in README to use the correct port [\#1221](https://github.com/samvera/active_fedora/pull/1221) ([escowles](https://github.com/escowles))
- Empty out nodes directly. [\#1215](https://github.com/samvera/active_fedora/pull/1215) ([tpendragon](https://github.com/tpendragon))
- Removing an exclusion for a non-existent file [\#1214](https://github.com/samvera/active_fedora/pull/1214) ([jeremyf](https://github.com/jeremyf))
- Fixing fcrepo\_wrapper behavior in `with\_server` task [\#1213](https://github.com/samvera/active_fedora/pull/1213) ([jeremyf](https://github.com/jeremyf))
- Fix ActiveFedora::Inheritance.base\_class for deep File descendants [\#1211](https://github.com/samvera/active_fedora/pull/1211) ([mbklein](https://github.com/mbklein))
- print IDs in more error messages [\#1206](https://github.com/samvera/active_fedora/pull/1206) ([dunn](https://github.com/dunn))

## [v11.1.5](https://github.com/samvera/active_fedora/tree/v11.1.5) (2017-03-07)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v11.1.4...v11.1.5)

**Merged pull requests:**

- Bump to version 11.1.5 [\#1210](https://github.com/samvera/active_fedora/pull/1210) ([hortongn](https://github.com/hortongn))
- When updating triples avoid the cache [\#1209](https://github.com/samvera/active_fedora/pull/1209) ([jcoyne](https://github.com/jcoyne))
- Add documentation about init\_root\_path [\#1208](https://github.com/samvera/active_fedora/pull/1208) ([jcoyne](https://github.com/jcoyne))
- Update rubocop to the latest release [\#1207](https://github.com/samvera/active_fedora/pull/1207) ([jcoyne](https://github.com/jcoyne))
- Bump version to 11.1.3 [\#1203](https://github.com/samvera/active_fedora/pull/1203) ([jcoyne](https://github.com/jcoyne))

## [v11.1.4](https://github.com/samvera/active_fedora/tree/v11.1.4) (2017-02-09)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v7.3.1...v11.1.4)

**Merged pull requests:**

- Don't populate attached\_files when using idiomatic basic containment [\#1205](https://github.com/samvera/active_fedora/pull/1205) ([jcoyne](https://github.com/jcoyne))

## [v7.3.1](https://github.com/samvera/active_fedora/tree/v7.3.1) (2017-02-09)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v7.3.0...v7.3.1)

**Merged pull requests:**

- Fix dependency snafu [\#1204](https://github.com/samvera/active_fedora/pull/1204) ([dchandekstark](https://github.com/dchandekstark))

## [v7.3.0](https://github.com/samvera/active_fedora/tree/v7.3.0) (2017-02-09)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v11.1.3...v7.3.0)

**Merged pull requests:**

- Loosened Rubydora dependency for 2.x. [\#1200](https://github.com/samvera/active_fedora/pull/1200) ([dchandekstark](https://github.com/dchandekstark))
- Belongs-to fallback should gracefully fail when unable to find associ… [\#1161](https://github.com/samvera/active_fedora/pull/1161) ([cbeer](https://github.com/cbeer))

## [v11.1.3](https://github.com/samvera/active_fedora/tree/v11.1.3) (2017-02-09)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v8.4.0...v11.1.3)

**Merged pull requests:**

- Refresh container resource triples [\#1202](https://github.com/samvera/active_fedora/pull/1202) ([jcoyne](https://github.com/jcoyne))
- Add missing update! method [\#1196](https://github.com/samvera/active_fedora/pull/1196) ([jcoyne](https://github.com/jcoyne))
- Allow Solrizer version 4.0 [\#1195](https://github.com/samvera/active_fedora/pull/1195) ([jcoyne](https://github.com/jcoyne))
- Explain which id could not be found [\#1194](https://github.com/samvera/active_fedora/pull/1194) ([jcoyne](https://github.com/jcoyne))
- Register ObjectNotFoundError as an Error ActionDispatch rescues [\#1193](https://github.com/samvera/active_fedora/pull/1193) ([jcoyne](https://github.com/jcoyne))

## [v8.4.0](https://github.com/samvera/active_fedora/tree/v8.4.0) (2017-02-03)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v11.1.2...v8.4.0)

**Merged pull requests:**

- Version 8.4.0 [\#1198](https://github.com/samvera/active_fedora/pull/1198) ([dchandekstark](https://github.com/dchandekstark))
- Loosens rubydora dependency to allow using 2.x [\#1197](https://github.com/samvera/active_fedora/pull/1197) ([dchandekstark](https://github.com/dchandekstark))

## [v11.1.2](https://github.com/samvera/active_fedora/tree/v11.1.2) (2017-01-25)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v11.1.1...v11.1.2)

**Closed issues:**

- Avoid using id\_to\_uri? [\#1189](https://github.com/samvera/active_fedora/issues/1189)
- NullLogger should respond to `debug?` [\#1184](https://github.com/samvera/active_fedora/issues/1184)

**Merged pull requests:**

- Eager load all the code in eager\_load blocks [\#1192](https://github.com/samvera/active_fedora/pull/1192) ([jcoyne](https://github.com/jcoyne))
- Eager load ActiveFedora [\#1191](https://github.com/samvera/active_fedora/pull/1191) ([jcoyne](https://github.com/jcoyne))
- Ensuring up to date system gems [\#1190](https://github.com/samvera/active_fedora/pull/1190) ([jeremyf](https://github.com/jeremyf))
- Warn if you don't pass :rows to SolrService.query [\#1188](https://github.com/samvera/active_fedora/pull/1188) ([jcoyne](https://github.com/jcoyne))
- Ensuring NullLogger responds to logging questions [\#1187](https://github.com/samvera/active_fedora/pull/1187) ([jeremyf](https://github.com/jeremyf))

## [v11.1.1](https://github.com/samvera/active_fedora/tree/v11.1.1) (2017-01-14)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v11.1.0...v11.1.1)

**Merged pull requests:**

- Don't modify passed in attributes [\#1186](https://github.com/samvera/active_fedora/pull/1186) ([jcoyne](https://github.com/jcoyne))
- When rails initializes, set the log if it previously was a NullLogger [\#1185](https://github.com/samvera/active_fedora/pull/1185) ([jcoyne](https://github.com/jcoyne))

## [v11.1.0](https://github.com/samvera/active_fedora/tree/v11.1.0) (2017-01-13)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v8.3.0...v11.1.0)

**Merged pull requests:**

- Casting an RDF::URI to a RDF::URI is unnecessary [\#1183](https://github.com/samvera/active_fedora/pull/1183) ([jcoyne](https://github.com/jcoyne))
- Replace deprecated Fixnum with Integer [\#1182](https://github.com/samvera/active_fedora/pull/1182) ([jcoyne](https://github.com/jcoyne))
- Removing invalid namespaces from tests [\#1181](https://github.com/samvera/active_fedora/pull/1181) ([escowles](https://github.com/escowles))
- Correct the documentation [\#1180](https://github.com/samvera/active_fedora/pull/1180) ([jcoyne](https://github.com/jcoyne))
- Fix reindex\_everything for use with active\_fedora-noid [\#1175](https://github.com/samvera/active_fedora/pull/1175) ([cjcolvar](https://github.com/cjcolvar))
- There is no need to pin rake any longer [\#1174](https://github.com/samvera/active_fedora/pull/1174) ([jcoyne](https://github.com/jcoyne))
- Allow logger to be set by default. Fixes \#1170 [\#1171](https://github.com/samvera/active_fedora/pull/1171) ([jcoyne](https://github.com/jcoyne))
- Add return value YARD doc [\#1169](https://github.com/samvera/active_fedora/pull/1169) ([jcoyne](https://github.com/jcoyne))
- Update to latest Rubocop [\#1168](https://github.com/samvera/active_fedora/pull/1168) ([awead](https://github.com/awead))
- Stop spamming IRC with Travis builds [\#1166](https://github.com/samvera/active_fedora/pull/1166) ([mjgiarlo](https://github.com/mjgiarlo))
- Changing file to accept any object that responds to URI including ano… [\#1162](https://github.com/samvera/active_fedora/pull/1162) ([carolyncole](https://github.com/carolyncole))
- Test with rsolr 2.x [\#1155](https://github.com/samvera/active_fedora/pull/1155) ([cbeer](https://github.com/cbeer))
- Use ActiveFedora::NullLogger [\#1153](https://github.com/samvera/active_fedora/pull/1153) ([awead](https://github.com/awead))

## [v8.3.0](https://github.com/samvera/active_fedora/tree/v8.3.0) (2016-11-21)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v10.3.0...v8.3.0)

**Merged pull requests:**

- Don't whitelist rubydora connection options [\#1176](https://github.com/samvera/active_fedora/pull/1176) ([cbeer](https://github.com/cbeer))

## [v10.3.0](https://github.com/samvera/active_fedora/tree/v10.3.0) (2016-11-21)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v8.2.2...v10.3.0)

**Merged pull requests:**

- Backport base\_uri method to keep reindex\_everything from erring with new af-noid [\#1178](https://github.com/samvera/active_fedora/pull/1178) ([hackmastera](https://github.com/hackmastera))

## [v8.2.2](https://github.com/samvera/active_fedora/tree/v8.2.2) (2016-11-17)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.7.3...v8.2.2)

**Closed issues:**

- Update external content handling for Fedora 4.7.0-RC [\#1156](https://github.com/samvera/active_fedora/issues/1156)

**Merged pull requests:**

- Override \#inherited instead of using deprecated alias\_method\_chain [\#1177](https://github.com/samvera/active_fedora/pull/1177) ([cbeer](https://github.com/cbeer))
- Fix up tests broken by rspec 2 -\> 3 conversion [\#1164](https://github.com/samvera/active_fedora/pull/1164) ([cbeer](https://github.com/cbeer))
- Convert specs to RSpec 3.5.4 syntax with Transpec [\#1163](https://github.com/samvera/active_fedora/pull/1163) ([cbeer](https://github.com/cbeer))

## [v9.7.3](https://github.com/samvera/active_fedora/tree/v9.7.3) (2016-10-31)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v8.2.1...v9.7.3)

**Closed issues:**

- Logger causes infinite recursion [\#1170](https://github.com/samvera/active_fedora/issues/1170)

**Merged pull requests:**

- Eliminate an unnecessary read of local content [\#1172](https://github.com/samvera/active_fedora/pull/1172) ([carolyncole](https://github.com/carolyncole))

## [v8.2.1](https://github.com/samvera/active_fedora/tree/v8.2.1) (2016-10-18)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v8.2.0...v8.2.1)

**Merged pull requests:**

- Belongs-to fallback should gracefully fail when unable to find associ… [\#1160](https://github.com/samvera/active_fedora/pull/1160) ([cbeer](https://github.com/cbeer))

## [v8.2.0](https://github.com/samvera/active_fedora/tree/v8.2.0) (2016-10-17)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v7.2.0...v8.2.0)

**Merged pull requests:**

- 8x optimize [\#1159](https://github.com/samvera/active_fedora/pull/1159) ([cbeer](https://github.com/cbeer))

## [v7.2.0](https://github.com/samvera/active_fedora/tree/v7.2.0) (2016-10-17)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.8.0...v7.2.0)

**Merged pull requests:**

- Short-circuit belongs\_to association lookups [\#1158](https://github.com/samvera/active_fedora/pull/1158) ([cbeer](https://github.com/cbeer))

## [v6.8.0](https://github.com/samvera/active_fedora/tree/v6.8.0) (2016-10-13)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v11.0.1...v6.8.0)

**Merged pull requests:**

- 6x dependencies [\#1157](https://github.com/samvera/active_fedora/pull/1157) ([cbeer](https://github.com/cbeer))

## [v11.0.1](https://github.com/samvera/active_fedora/tree/v11.0.1) (2016-09-22)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v11.0.0...v11.0.1)

**Merged pull requests:**

- Guard for nil logger [\#1152](https://github.com/samvera/active_fedora/pull/1152) ([jcoyne](https://github.com/jcoyne))
- Cast RDF Literals to strings when indexing. [\#1151](https://github.com/samvera/active_fedora/pull/1151) ([tpendragon](https://github.com/tpendragon))

## [v11.0.0](https://github.com/samvera/active_fedora/tree/v11.0.0) (2016-09-13)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v10.3.0.rc2...v11.0.0)

**Closed issues:**

- Remove .send call from FedoraAttributes/OrderedList [\#1111](https://github.com/samvera/active_fedora/issues/1111)
- Enforce cardinality of properties on ActiveFedora::RDFDatastream like it is for ActiveFedora::Base [\#776](https://github.com/samvera/active_fedora/issues/776)
- RDF::StrictVocabulary.term is introduced in rdf 1.1.4 [\#669](https://github.com/samvera/active_fedora/issues/669)
- Add rdf-vocab 0.4.0 dependency and remove vocabs [\#651](https://github.com/samvera/active_fedora/issues/651)

**Merged pull requests:**

- Upgrade to ActiveTriples 0.11 [\#1149](https://github.com/samvera/active_fedora/pull/1149) ([jcoyne](https://github.com/jcoyne))
- Rename to\_class\_uri to to\_rdf\_representation [\#1148](https://github.com/samvera/active_fedora/pull/1148) ([jcoyne](https://github.com/jcoyne))
- Querying for relationships should use solr raw query [\#1147](https://github.com/samvera/active_fedora/pull/1147) ([jcoyne](https://github.com/jcoyne))
- Update rspec configuration with new default settings [\#1145](https://github.com/samvera/active_fedora/pull/1145) ([cbeer](https://github.com/cbeer))
- Bump dependency on rsolr to \>= 1.1.2 [\#1144](https://github.com/samvera/active_fedora/pull/1144) ([jcoyne](https://github.com/jcoyne))
- Remove unused methods [\#1143](https://github.com/samvera/active_fedora/pull/1143) ([jcoyne](https://github.com/jcoyne))
- Additional datastreams cleanup [\#1142](https://github.com/samvera/active_fedora/pull/1142) ([cbeer](https://github.com/cbeer))

## [v10.3.0.rc2](https://github.com/samvera/active_fedora/tree/v10.3.0.rc2) (2016-08-18)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v11.0.0.rc7...v10.3.0.rc2)

## [v11.0.0.rc7](https://github.com/samvera/active_fedora/tree/v11.0.0.rc7) (2016-08-18)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v10.3.0.rc1...v11.0.0.rc7)

**Merged pull requests:**

- Lookup inverse using predicate [\#1141](https://github.com/samvera/active_fedora/pull/1141) ([jcoyne](https://github.com/jcoyne))
- Remove delegates to removed methods [\#1139](https://github.com/samvera/active_fedora/pull/1139) ([cjcolvar](https://github.com/cjcolvar))
- Remove Datastreams [\#1130](https://github.com/samvera/active_fedora/pull/1130) ([jcoyne](https://github.com/jcoyne))

## [v10.3.0.rc1](https://github.com/samvera/active_fedora/tree/v10.3.0.rc1) (2016-08-18)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v11.0.0.rc6...v10.3.0.rc1)

**Merged pull requests:**

- Accept attributes that have the correct methods [\#1140](https://github.com/samvera/active_fedora/pull/1140) ([jcoyne](https://github.com/jcoyne))

## [v11.0.0.rc6](https://github.com/samvera/active_fedora/tree/v11.0.0.rc6) (2016-08-12)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v10.2.1...v11.0.0.rc6)

**Merged pull requests:**

- Solr wrapper bump [\#1136](https://github.com/samvera/active_fedora/pull/1136) ([atz](https://github.com/atz))
- solr\_wrapper now uses the generated solr configs for testing AF instead of a separate directory tree of Solr configs [\#1135](https://github.com/samvera/active_fedora/pull/1135) ([mjgiarlo](https://github.com/mjgiarlo))
- Bump rubocop-rspec version [\#1134](https://github.com/samvera/active_fedora/pull/1134) ([atz](https://github.com/atz))
- Adding in the terms handler so that generated apps include this by default [\#1120](https://github.com/samvera/active_fedora/pull/1120) ([carolyncole](https://github.com/carolyncole))

## [v10.2.1](https://github.com/samvera/active_fedora/tree/v10.2.1) (2016-08-12)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v11.0.0.rc5...v10.2.1)

**Merged pull requests:**

- solr\_wrapper now uses generated configs for testing [\#1137](https://github.com/samvera/active_fedora/pull/1137) ([mjgiarlo](https://github.com/mjgiarlo))

## [v11.0.0.rc5](https://github.com/samvera/active_fedora/tree/v11.0.0.rc5) (2016-08-11)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v11.0.0.rc4...v11.0.0.rc5)

**Merged pull requests:**

- Bump ldp dependency to 0.6.0 [\#1133](https://github.com/samvera/active_fedora/pull/1133) ([jcoyne](https://github.com/jcoyne))

## [v11.0.0.rc4](https://github.com/samvera/active_fedora/tree/v11.0.0.rc4) (2016-08-10)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v10.2.0...v11.0.0.rc4)

**Merged pull requests:**

- Remove linkeddata. [\#1131](https://github.com/samvera/active_fedora/pull/1131) ([jcoyne](https://github.com/jcoyne))

## [v10.2.0](https://github.com/samvera/active_fedora/tree/v10.2.0) (2016-08-10)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v11.0.0.rc3...v10.2.0)

**Merged pull requests:**

- Remove linkeddata \(following \#1131\) -- backport to latest stable branch [\#1132](https://github.com/samvera/active_fedora/pull/1132) ([mjgiarlo](https://github.com/mjgiarlo))
- Align solr config from Sufia with what's in AF [\#1129](https://github.com/samvera/active_fedora/pull/1129) ([mjgiarlo](https://github.com/mjgiarlo))
- Deprecate calling ActiveFedora::Base\#initialize with a String argument [\#1126](https://github.com/samvera/active_fedora/pull/1126) ([jcoyne](https://github.com/jcoyne))

## [v11.0.0.rc3](https://github.com/samvera/active_fedora/tree/v11.0.0.rc3) (2016-08-10)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v11.0.0.rc2...v11.0.0.rc3)

**Closed issues:**

- ActionController::Parameters is not acceptable. [\#1122](https://github.com/samvera/active_fedora/issues/1122)

**Merged pull requests:**

- Refactor spec [\#1128](https://github.com/samvera/active_fedora/pull/1128) ([jcoyne](https://github.com/jcoyne))
- Remove ActiveFedora::Base\#initialize with a String argument [\#1127](https://github.com/samvera/active_fedora/pull/1127) ([jcoyne](https://github.com/jcoyne))

## [v11.0.0.rc2](https://github.com/samvera/active_fedora/tree/v11.0.0.rc2) (2016-08-09)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v11.0.0.rc1...v11.0.0.rc2)

**Merged pull requests:**

- Reference actual classes [\#1121](https://github.com/samvera/active_fedora/pull/1121) ([jcoyne](https://github.com/jcoyne))
- Fixing for latest rubocop-rspec [\#1119](https://github.com/samvera/active_fedora/pull/1119) ([carolyncole](https://github.com/carolyncole))

## [v11.0.0.rc1](https://github.com/samvera/active_fedora/tree/v11.0.0.rc1) (2016-07-29)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v10.1.0...v11.0.0.rc1)

**Merged pull requests:**

- Model template uses has\_subresource. Fixes \#1090 [\#1118](https://github.com/samvera/active_fedora/pull/1118) ([jcoyne](https://github.com/jcoyne))
- Run rubocop before starting the test server [\#1117](https://github.com/samvera/active_fedora/pull/1117) ([jcoyne](https://github.com/jcoyne))
- Throw abort to terminate callbacks [\#1116](https://github.com/samvera/active_fedora/pull/1116) ([jcoyne](https://github.com/jcoyne))
- Remove load\_instance\_from\_solr [\#1113](https://github.com/samvera/active_fedora/pull/1113) ([jcoyne](https://github.com/jcoyne))
- Update to latest rubocop and rubocop-rspec [\#1112](https://github.com/samvera/active_fedora/pull/1112) ([jcoyne](https://github.com/jcoyne))
- Performance Improvements [\#1109](https://github.com/samvera/active_fedora/pull/1109) ([tpendragon](https://github.com/tpendragon))
- Update Active Triples [\#1107](https://github.com/samvera/active_fedora/pull/1107) ([jcoyne](https://github.com/jcoyne))

## [v10.1.0](https://github.com/samvera/active_fedora/tree/v10.1.0) (2016-07-29)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v10.1.0.rc1...v10.1.0)

**Fixed bugs:**

- Naming of contains, directly\_contains, etc. on Reflection class is confusing  [\#811](https://github.com/samvera/active_fedora/issues/811)

**Closed issues:**

- Remove indexed profile \(or turn it off by default\) [\#1110](https://github.com/samvera/active_fedora/issues/1110)
- Model template uses removed method `contains` [\#1090](https://github.com/samvera/active_fedora/issues/1090)
- Can't load a belongs\_to association on a record loaded from solr. [\#946](https://github.com/samvera/active_fedora/issues/946)
- load\_instance\_from\_solr causes multivalue error. [\#877](https://github.com/samvera/active_fedora/issues/877)
- Rdf datastreams get loaded on AF::Base.find [\#33](https://github.com/samvera/active_fedora/issues/33)

**Merged pull requests:**

- Deprecate load\_instance\_from\_solr [\#1115](https://github.com/samvera/active_fedora/pull/1115) ([jcoyne](https://github.com/jcoyne))

## [v10.1.0.rc1](https://github.com/samvera/active_fedora/tree/v10.1.0.rc1) (2016-07-11)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.7.2...v10.1.0.rc1)

**Fixed bugs:**

- ActiveFedora::WithMetadata::MetadataNode\#save isn't working [\#1083](https://github.com/samvera/active_fedora/issues/1083)

**Merged pull requests:**

- Sending multiple values from a where cluase will join with OR [\#1106](https://github.com/samvera/active_fedora/pull/1106) ([carolyncole](https://github.com/carolyncole))
- Remove autoload of non-existant class [\#1099](https://github.com/samvera/active_fedora/pull/1099) ([jcoyne](https://github.com/jcoyne))
- Deprecate datastreams [\#1098](https://github.com/samvera/active_fedora/pull/1098) ([jcoyne](https://github.com/jcoyne))
- Remove prefix method from File [\#1097](https://github.com/samvera/active_fedora/pull/1097) ([jcoyne](https://github.com/jcoyne))
- Remove unused methods from OmDatastream [\#1096](https://github.com/samvera/active_fedora/pull/1096) ([jcoyne](https://github.com/jcoyne))
- Remove configure\_jetty rake task [\#1095](https://github.com/samvera/active_fedora/pull/1095) ([jcoyne](https://github.com/jcoyne))

## [v9.7.2](https://github.com/samvera/active_fedora/tree/v9.7.2) (2016-07-01)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v10.0.0...v9.7.2)

**Merged pull requests:**

- Adding the ability to join with OR from a where clause [\#1103](https://github.com/samvera/active_fedora/pull/1103) ([carolyncole](https://github.com/carolyncole))
- Fixing rubocop for latest version [\#1102](https://github.com/samvera/active_fedora/pull/1102) ([carolyncole](https://github.com/carolyncole))

## [v10.0.0](https://github.com/samvera/active_fedora/tree/v10.0.0) (2016-06-08)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v10.0.0.beta4...v10.0.0)

**Merged pull requests:**

- Fix the description on a test so that it's acurate [\#1094](https://github.com/samvera/active_fedora/pull/1094) ([jcoyne](https://github.com/jcoyne))

## [v10.0.0.beta4](https://github.com/samvera/active_fedora/tree/v10.0.0.beta4) (2016-06-03)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v10.0.0.beta3...v10.0.0.beta4)

**Merged pull requests:**

- Stop indexing on active\_fedora\_model\_ssi [\#1093](https://github.com/samvera/active_fedora/pull/1093) ([jcoyne](https://github.com/jcoyne))
- AF::File\#save! should persist metadata [\#1091](https://github.com/samvera/active_fedora/pull/1091) ([jcoyne](https://github.com/jcoyne))

## [v10.0.0.beta3](https://github.com/samvera/active_fedora/tree/v10.0.0.beta3) (2016-05-23)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v10.0.0.beta2...v10.0.0.beta3)

**Implemented enhancements:**

- Missing an ActiveFedora::File\#content? method [\#1082](https://github.com/samvera/active_fedora/issues/1082)

**Closed issues:**

- Updating ActiveFedora::File.mime-type [\#890](https://github.com/samvera/active_fedora/issues/890)

**Merged pull requests:**

- Filter out records marked\_as\_deleted [\#1089](https://github.com/samvera/active_fedora/pull/1089) ([jcoyne](https://github.com/jcoyne))
- Eliminate an unnecessary read of local content [\#1088](https://github.com/samvera/active_fedora/pull/1088) ([jcoyne](https://github.com/jcoyne))
- Set the solrizer logger in the railtie. Fixes \#997 [\#1087](https://github.com/samvera/active_fedora/pull/1087) ([jcoyne](https://github.com/jcoyne))
- Make the MetadataNode conform to the AF::Base API [\#1086](https://github.com/samvera/active_fedora/pull/1086) ([jcoyne](https://github.com/jcoyne))
- remove unnecessary require of deprecation [\#1085](https://github.com/samvera/active_fedora/pull/1085) ([jcoyne](https://github.com/jcoyne))
- ActiveFedora::File.mime\_type should be updatable. Fixes \#890, \#1083 [\#1084](https://github.com/samvera/active_fedora/pull/1084) ([mjgiarlo](https://github.com/mjgiarlo))
- Restore defaults to with\_server [\#1079](https://github.com/samvera/active_fedora/pull/1079) ([jcoyne](https://github.com/jcoyne))

## [v10.0.0.beta2](https://github.com/samvera/active_fedora/tree/v10.0.0.beta2) (2016-05-12)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v10.0.0.beta1...v10.0.0.beta2)

**Closed issues:**

- Assigning a singular minted relationship value to a non-multiple property causes an error? [\#1067](https://github.com/samvera/active_fedora/issues/1067)

**Merged pull requests:**

- Using generated config files for fedora & solr [\#1078](https://github.com/samvera/active_fedora/pull/1078) ([escowles](https://github.com/escowles))
- Metadata class factory [\#1077](https://github.com/samvera/active_fedora/pull/1077) ([awead](https://github.com/awead))

## [v10.0.0.beta1](https://github.com/samvera/active_fedora/tree/v10.0.0.beta1) (2016-05-10)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.13.0...v10.0.0.beta1)

## [v9.13.0](https://github.com/samvera/active_fedora/tree/v9.13.0) (2016-05-09)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.12.0...v9.13.0)

**Merged pull requests:**

- Remove deprecations in preparation for AF 10.0 [\#1076](https://github.com/samvera/active_fedora/pull/1076) ([jcoyne](https://github.com/jcoyne))
- Deprecate AF::SimpleDatastream [\#1075](https://github.com/samvera/active_fedora/pull/1075) ([jcoyne](https://github.com/jcoyne))
- Use Deprecation.warn on AS::Concern ClassMethods [\#1074](https://github.com/samvera/active_fedora/pull/1074) ([jcoyne](https://github.com/jcoyne))
- Add a Basic Container association [\#1073](https://github.com/samvera/active_fedora/pull/1073) ([jcoyne](https://github.com/jcoyne))
- Renamed `contains` to `has\_subresource` [\#1072](https://github.com/samvera/active_fedora/pull/1072) ([jcoyne](https://github.com/jcoyne))
- Have generators create wrapper config files for test [\#1071](https://github.com/samvera/active_fedora/pull/1071) ([mark-dce](https://github.com/mark-dce))
- Update solr\_wrapper and fcrepo\_wrapper dot-file defaults [\#1070](https://github.com/samvera/active_fedora/pull/1070) ([mark-dce](https://github.com/mark-dce))
- Don't raise an error if you check if a deleted object is new [\#1069](https://github.com/samvera/active_fedora/pull/1069) ([jcoyne](https://github.com/jcoyne))
- Suppress AF::Cleaner errors when running the test suite [\#1066](https://github.com/samvera/active_fedora/pull/1066) ([cbeer](https://github.com/cbeer))
- Defer `init\_base\_path` until it is required [\#1065](https://github.com/samvera/active_fedora/pull/1065) ([cbeer](https://github.com/cbeer))

## [v9.12.0](https://github.com/samvera/active_fedora/tree/v9.12.0) (2016-04-19)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.11.0...v9.12.0)

**Fixed bugs:**

- model returned by ActiveFedora::SolrHit. instantiate\_with\_json is persisted? -\> false [\#1054](https://github.com/samvera/active_fedora/issues/1054)
- File streaming does not account for SSL [\#992](https://github.com/samvera/active_fedora/issues/992)

**Merged pull requests:**

- Update graph instead of destroying it [\#1063](https://github.com/samvera/active_fedora/pull/1063) ([narogers](https://github.com/narogers))
- \#992 detect https url for FCREPO and use\_ssl appropriately [\#1062](https://github.com/samvera/active_fedora/pull/1062) ([barmintor](https://github.com/barmintor))
- Update SolrService.register to support passing in the url as one of the option keys [\#1061](https://github.com/samvera/active_fedora/pull/1061) ([cbeer](https://github.com/cbeer))
- SolrHit\#instantiate\_with\_json should create persisted objects [\#1056](https://github.com/samvera/active_fedora/pull/1056) ([cbeer](https://github.com/cbeer))

## [v9.11.0](https://github.com/samvera/active_fedora/tree/v9.11.0) (2016-04-15)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.10.4...v9.11.0)

**Closed issues:**

- Update Schema.xml for Solr 6 [\#1058](https://github.com/samvera/active_fedora/issues/1058)
- Streamed content doesn't follow redirects [\#1051](https://github.com/samvera/active_fedora/issues/1051)
- Release Notes for Fedora4 [\#639](https://github.com/samvera/active_fedora/issues/639)

**Merged pull requests:**

- Update schema for Solr 6 [\#1059](https://github.com/samvera/active_fedora/pull/1059) ([atz](https://github.com/atz))
- Update schema for Solr 5+6 compatibility [\#1057](https://github.com/samvera/active_fedora/pull/1057) ([cbeer](https://github.com/cbeer))
- Fedora 4.5.1-RC compatibility [\#1053](https://github.com/samvera/active_fedora/pull/1053) ([escowles](https://github.com/escowles))
- follow redirects for content streaming, closes \#1051 [\#1052](https://github.com/samvera/active_fedora/pull/1052) ([lbiedinger](https://github.com/lbiedinger))
- Push AF::Fedora\#init\_base\_path down into \#connection [\#1050](https://github.com/samvera/active_fedora/pull/1050) ([cbeer](https://github.com/cbeer))
- Add DangerousAttributeError exception and test the triggering case [\#1049](https://github.com/samvera/active_fedora/pull/1049) ([cbeer](https://github.com/cbeer))
- Align new aggregation associations with existing conventions [\#1048](https://github.com/samvera/active_fedora/pull/1048) ([cbeer](https://github.com/cbeer))
- Use a version of activesupport \>= 4.2.4 [\#1047](https://github.com/samvera/active_fedora/pull/1047) ([jcoyne](https://github.com/jcoyne))
- Pass the block from find\_in\_batches to search\_in\_batches [\#1045](https://github.com/samvera/active_fedora/pull/1045) ([jcoyne](https://github.com/jcoyne))
- Enable `dependent: destroy` for HasManyAssociation [\#1044](https://github.com/samvera/active_fedora/pull/1044) ([jcoyne](https://github.com/jcoyne))
- Merge activefedora-aggregations into active-fedora [\#1043](https://github.com/samvera/active_fedora/pull/1043) ([cbeer](https://github.com/cbeer))
- ActiveFedora::RecordInvalid should be a ActiveFedoraError [\#1042](https://github.com/samvera/active_fedora/pull/1042) ([cbeer](https://github.com/cbeer))

## [v9.10.4](https://github.com/samvera/active_fedora/tree/v9.10.4) (2016-03-28)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.10.3...v9.10.4)

**Closed issues:**

- Updating mime-type puts FCRepo 4.5.0 in a bad state [\#1046](https://github.com/samvera/active_fedora/issues/1046)

## [v9.10.3](https://github.com/samvera/active_fedora/tree/v9.10.3) (2016-03-28)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.10.2...v9.10.3)

## [v9.10.2](https://github.com/samvera/active_fedora/tree/v9.10.2) (2016-03-28)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.10.1...v9.10.2)

## [v9.10.1](https://github.com/samvera/active_fedora/tree/v9.10.1) (2016-03-25)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.10.0...v9.10.1)

**Merged pull requests:**

- Remove extra underscore from reflect\_on\_association [\#1041](https://github.com/samvera/active_fedora/pull/1041) ([tpendragon](https://github.com/tpendragon))

## [v9.10.0](https://github.com/samvera/active_fedora/tree/v9.10.0) (2016-03-24)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.10.0.pre2...v9.10.0)

**Merged pull requests:**

- Continued alignment of associations with upstream changes [\#1038](https://github.com/samvera/active_fedora/pull/1038) ([cbeer](https://github.com/cbeer))
- Update reflections and associations [\#1037](https://github.com/samvera/active_fedora/pull/1037) ([cbeer](https://github.com/cbeer))
- Wrapper config [\#1036](https://github.com/samvera/active_fedora/pull/1036) ([jcoyne](https://github.com/jcoyne))
- ActiveFedora::File.mime\_type should be updatable [\#1035](https://github.com/samvera/active_fedora/pull/1035) ([cjcolvar](https://github.com/cjcolvar))

## [v9.10.0.pre2](https://github.com/samvera/active_fedora/tree/v9.10.0.pre2) (2016-03-22)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.10.0.pre1...v9.10.0.pre2)

**Closed issues:**

- has\_many assertions that are not persisted are not showing in size [\#1030](https://github.com/samvera/active_fedora/issues/1030)

**Merged pull requests:**

- Deprecate delegating attributes to associated objects [\#1034](https://github.com/samvera/active_fedora/pull/1034) ([jcoyne](https://github.com/jcoyne))
- Update AF::AttributeMethods with upstream changes [\#1033](https://github.com/samvera/active_fedora/pull/1033) ([cbeer](https://github.com/cbeer))
- Correctly find the size of a collection in memory [\#1032](https://github.com/samvera/active_fedora/pull/1032) ([jcoyne](https://github.com/jcoyne))
- Update scoping with latest upstream changes [\#1031](https://github.com/samvera/active_fedora/pull/1031) ([cbeer](https://github.com/cbeer))
- Update callbacks with upstream improvements [\#1028](https://github.com/samvera/active_fedora/pull/1028) ([cbeer](https://github.com/cbeer))

## [v9.10.0.pre1](https://github.com/samvera/active_fedora/tree/v9.10.0.pre1) (2016-03-19)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.9.1...v9.10.0.pre1)

**Closed issues:**

- has\_many for a new owner is returning all the orphan records [\#1008](https://github.com/samvera/active_fedora/issues/1008)
- ActiveFedora should set Solrizer.logger [\#997](https://github.com/samvera/active_fedora/issues/997)

**Merged pull requests:**

- Update Validations with latest upstream changes [\#1029](https://github.com/samvera/active_fedora/pull/1029) ([cbeer](https://github.com/cbeer))
- Delegate count to the scope [\#1027](https://github.com/samvera/active_fedora/pull/1027) ([jcoyne](https://github.com/jcoyne))
- Update nested attributes with upstream improvements [\#1026](https://github.com/samvera/active_fedora/pull/1026) ([cbeer](https://github.com/cbeer))
- Update minimum versions of ruby and activesupport [\#1025](https://github.com/samvera/active_fedora/pull/1025) ([cbeer](https://github.com/cbeer))
- Begin updating associations to latest Rails conventions [\#1024](https://github.com/samvera/active_fedora/pull/1024) ([cbeer](https://github.com/cbeer))
- Unconditionally run coverage reports when running tests [\#1023](https://github.com/samvera/active_fedora/pull/1023) ([cbeer](https://github.com/cbeer))
- Remove or deprecate unused code [\#1022](https://github.com/samvera/active_fedora/pull/1022) ([cbeer](https://github.com/cbeer))
- Extract SolrService.get to send requests to Solr and get the original response [\#1020](https://github.com/samvera/active_fedora/pull/1020) ([cbeer](https://github.com/cbeer))
- Silence SolrQueryBuilder deprecation warnings when running tests [\#1019](https://github.com/samvera/active_fedora/pull/1019) ([cbeer](https://github.com/cbeer))
- Simplify ActiveFedora::SolrQueryBuilder [\#1018](https://github.com/samvera/active_fedora/pull/1018) ([cbeer](https://github.com/cbeer))
- Deprecate unused methods [\#1016](https://github.com/samvera/active_fedora/pull/1016) ([jcoyne](https://github.com/jcoyne))
- ActiveFedora depends on Solrizer [\#1015](https://github.com/samvera/active_fedora/pull/1015) ([jcoyne](https://github.com/jcoyne))
- Don't rely on exceptions for flow control [\#1014](https://github.com/samvera/active_fedora/pull/1014) ([jcoyne](https://github.com/jcoyne))
- Update testing versions of Ruby and Rails [\#1013](https://github.com/samvera/active_fedora/pull/1013) ([jcoyne](https://github.com/jcoyne))
- Add default scopes [\#1012](https://github.com/samvera/active_fedora/pull/1012) ([jcoyne](https://github.com/jcoyne))
- Extract SolrHit class to wrap Solr response documents [\#1011](https://github.com/samvera/active_fedora/pull/1011) ([cbeer](https://github.com/cbeer))
- Push .search\_by\_id into ActiveFedora::FinderMethod [\#1010](https://github.com/samvera/active_fedora/pull/1010) ([cbeer](https://github.com/cbeer))
- Rename find\_with\_conditions and find\_in\_batches to search\_with\_conditions and search\_in\_batches [\#1009](https://github.com/samvera/active_fedora/pull/1009) ([cbeer](https://github.com/cbeer))
- Provide class-level accessors for solr configuration options [\#1007](https://github.com/samvera/active_fedora/pull/1007) ([cbeer](https://github.com/cbeer))
- Use the same logic for lazy\_reify\_solr\_results and reify\_solr\_results [\#1006](https://github.com/samvera/active_fedora/pull/1006) ([cbeer](https://github.com/cbeer))
- Move indexer to a class attribute [\#1005](https://github.com/samvera/active_fedora/pull/1005) ([jcoyne](https://github.com/jcoyne))
- Fix build breaking due to Rake 11.0.1, Rubocop 0.38.0 and ActiveModel 4.2.6 [\#1003](https://github.com/samvera/active_fedora/pull/1003) ([jcoyne](https://github.com/jcoyne))
- Unify type to model mapping code [\#1002](https://github.com/samvera/active_fedora/pull/1002) ([cbeer](https://github.com/cbeer))
- Update to use ldp 0.5 [\#1000](https://github.com/samvera/active_fedora/pull/1000) ([cbeer](https://github.com/cbeer))

## [v9.9.1](https://github.com/samvera/active_fedora/tree/v9.9.1) (2016-03-05)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.9.0...v9.9.1)

**Merged pull requests:**

- Restore autocommit in the update handler [\#999](https://github.com/samvera/active_fedora/pull/999) ([jcoyne](https://github.com/jcoyne))
- Update rubocop [\#998](https://github.com/samvera/active_fedora/pull/998) ([cbeer](https://github.com/cbeer))

## [v9.9.0](https://github.com/samvera/active_fedora/tree/v9.9.0) (2016-02-15)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.8.2...v9.9.0)

**Closed issues:**

- AF config needs a way to inject Faraday options [\#985](https://github.com/samvera/active_fedora/issues/985)

**Merged pull requests:**

- Update development configs to use environment variables [\#994](https://github.com/samvera/active_fedora/pull/994) ([jcoyne](https://github.com/jcoyne))
- Generalize the with\_server method [\#993](https://github.com/samvera/active_fedora/pull/993) ([jcoyne](https://github.com/jcoyne))
- Use local configurations for solr [\#990](https://github.com/samvera/active_fedora/pull/990) ([jcoyne](https://github.com/jcoyne))
- Share the test server method with downstream apps [\#988](https://github.com/samvera/active_fedora/pull/988) ([jcoyne](https://github.com/jcoyne))
- Adds SSL options to config \(closes \#985\) [\#986](https://github.com/samvera/active_fedora/pull/986) ([dchandekstark](https://github.com/dchandekstark))
- Fixes for rubocop 0.37.1 [\#984](https://github.com/samvera/active_fedora/pull/984) ([jcoyne](https://github.com/jcoyne))
- To be an XMLSchema\#dateTime the TZ must have a colon [\#983](https://github.com/samvera/active_fedora/pull/983) ([jcoyne](https://github.com/jcoyne))
- Add a rake task for running spec without rubocop [\#982](https://github.com/samvera/active_fedora/pull/982) ([jcoyne](https://github.com/jcoyne))
- Use the correct flag to fcrepo\_wrapper [\#981](https://github.com/samvera/active_fedora/pull/981) ([jcoyne](https://github.com/jcoyne))
- Don't default facet.limit [\#980](https://github.com/samvera/active_fedora/pull/980) ([jcoyne](https://github.com/jcoyne))
- Start solr and fedora on a random open port [\#979](https://github.com/samvera/active_fedora/pull/979) ([jcoyne](https://github.com/jcoyne))
- Add support for customizable Solr request handlers. [\#960](https://github.com/samvera/active_fedora/pull/960) ([ojlyytinen](https://github.com/ojlyytinen))

## [v9.8.2](https://github.com/samvera/active_fedora/tree/v9.8.2) (2016-02-05)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.8.1...v9.8.2)

**Closed issues:**

- rails g active\_fedora:config:solr should generate solr 5 configs [\#970](https://github.com/samvera/active_fedora/issues/970)

**Merged pull requests:**

- Restore the permissions handler [\#977](https://github.com/samvera/active_fedora/pull/977) ([jcoyne](https://github.com/jcoyne))
- Add extract handler to solrconfig [\#976](https://github.com/samvera/active_fedora/pull/976) ([jcoyne](https://github.com/jcoyne))
- Run test FCRepo on a separate instance from development [\#975](https://github.com/samvera/active_fedora/pull/975) ([jcoyne](https://github.com/jcoyne))

## [v9.8.1](https://github.com/samvera/active_fedora/tree/v9.8.1) (2016-02-05)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.8.0...v9.8.1)

**Fixed bugs:**

- AF::File callbacks are not triggered [\#972](https://github.com/samvera/active_fedora/issues/972)

**Merged pull requests:**

- Runs AF::File callbacks \(fixes \#972\) [\#973](https://github.com/samvera/active_fedora/pull/973) ([dchandekstark](https://github.com/dchandekstark))
- Generate solr 5 configs [\#971](https://github.com/samvera/active_fedora/pull/971) ([jcoyne](https://github.com/jcoyne))

## [v9.8.0](https://github.com/samvera/active_fedora/tree/v9.8.0) (2016-02-05)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.7.1...v9.8.0)

**Merged pull requests:**

- Remove unused files [\#969](https://github.com/samvera/active_fedora/pull/969) ([jcoyne](https://github.com/jcoyne))
- Test on Solr 5 [\#968](https://github.com/samvera/active_fedora/pull/968) ([jcoyne](https://github.com/jcoyne))
- Pass hash of options to index.as [\#966](https://github.com/samvera/active_fedora/pull/966) ([awead](https://github.com/awead))

## [v9.7.1](https://github.com/samvera/active_fedora/tree/v9.7.1) (2016-01-29)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.7.0...v9.7.1)

**Closed issues:**

- Whitespace entities not preserved in Fedora datastream [\#962](https://github.com/samvera/active_fedora/issues/962)
- after\_find not called in reload [\#961](https://github.com/samvera/active_fedora/issues/961)

**Merged pull requests:**

- The jcr/mix versionable predicate is no longer used [\#965](https://github.com/samvera/active_fedora/pull/965) ([awead](https://github.com/awead))
- Add detail to SolrQueryBuilder.construct\_query\_for\_pids deprecation [\#964](https://github.com/samvera/active_fedora/pull/964) ([dchandekstark](https://github.com/dchandekstark))
- Updating to the latest Rubocop [\#963](https://github.com/samvera/active_fedora/pull/963) ([awead](https://github.com/awead))
- Adds :PID property to ActiveFedora::RDF::Fcrepo::Model vocab [\#957](https://github.com/samvera/active_fedora/pull/957) ([dchandekstark](https://github.com/dchandekstark))

## [v9.7.0](https://github.com/samvera/active_fedora/tree/v9.7.0) (2015-11-30)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.6.2...v9.7.0)

**Closed issues:**

- Re-add and deprecate FileConfigurator.get\_config\_path [\#949](https://github.com/samvera/active_fedora/issues/949)
- Adding to a :has\_many relationship does not propagate errors. [\#78](https://github.com/samvera/active_fedora/issues/78)
- AF 5.x + Rubydora \>= 1.4 test failures [\#55](https://github.com/samvera/active_fedora/issues/55)

**Merged pull requests:**

- Allowing access to the gone? method from outside the object [\#955](https://github.com/samvera/active_fedora/pull/955) ([carolyncole](https://github.com/carolyncole))
- Silence deprecation warning in test [\#954](https://github.com/samvera/active_fedora/pull/954) ([jcoyne](https://github.com/jcoyne))
- Test deprecation using mocks [\#953](https://github.com/samvera/active_fedora/pull/953) ([jcoyne](https://github.com/jcoyne))
- Use rdf-vocab gem for DC vocab [\#952](https://github.com/samvera/active_fedora/pull/952) ([jcoyne](https://github.com/jcoyne))
- Give an error when the user queries for a non-existant reflection [\#951](https://github.com/samvera/active_fedora/pull/951) ([jcoyne](https://github.com/jcoyne))
- Re-add get\_config\_path method \(removed in 9.6.0\) with deprecation war… [\#950](https://github.com/samvera/active_fedora/pull/950) ([coblej](https://github.com/coblej))
- Adds explicit require of 'rdf/vocab' to AF::FedoraAttributes [\#945](https://github.com/samvera/active_fedora/pull/945) ([dchandekstark](https://github.com/dchandekstark))
- ids\_reader should not return duplicates. [\#944](https://github.com/samvera/active_fedora/pull/944) ([tpendragon](https://github.com/tpendragon))
- Fix YARD documentation [\#943](https://github.com/samvera/active_fedora/pull/943) ([jcoyne](https://github.com/jcoyne))
- Don't try to parse empty dates [\#939](https://github.com/samvera/active_fedora/pull/939) ([awead](https://github.com/awead))

## [v9.6.2](https://github.com/samvera/active_fedora/tree/v9.6.2) (2015-11-09)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.6.1...v9.6.2)

**Merged pull requests:**

- Escape square brackets in URIs. Fixes \#941 [\#942](https://github.com/samvera/active_fedora/pull/942) ([jcoyne](https://github.com/jcoyne))

## [v9.6.1](https://github.com/samvera/active_fedora/tree/v9.6.1) (2015-11-03)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.6.0...v9.6.1)

**Closed issues:**

- Cant convert nil to string. [\#937](https://github.com/samvera/active_fedora/issues/937)

**Merged pull requests:**

- Don't try to parse nil dates. Fixes \#937 [\#938](https://github.com/samvera/active_fedora/pull/938) ([jcoyne](https://github.com/jcoyne))

## [v9.6.0](https://github.com/samvera/active_fedora/tree/v9.6.0) (2015-11-02)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.5.0...v9.6.0)

**Closed issues:**

- Persistence\#save\_contained\_resources loads files just to see if they are changed [\#928](https://github.com/samvera/active_fedora/issues/928)
- serialize\_attached\_files should not load files [\#927](https://github.com/samvera/active_fedora/issues/927)
- ActiveFedor::File\#refresh should clear @ds\_content [\#913](https://github.com/samvera/active_fedora/issues/913)
- Create\_date and modified\_date raise errors with instances loaded from Solr [\#905](https://github.com/samvera/active_fedora/issues/905)
- solr loads only one nested attribute [\#870](https://github.com/samvera/active_fedora/issues/870)

**Merged pull requests:**

- Loosen dependency on rdf-rdfxml [\#936](https://github.com/samvera/active_fedora/pull/936) ([jcoyne](https://github.com/jcoyne))
- Allow developers to override resource\_class. [\#933](https://github.com/samvera/active_fedora/pull/933) ([tpendragon](https://github.com/tpendragon))
- Makes `has\_key?` and `key?` behave consistently in AF::AssociationHash [\#932](https://github.com/samvera/active_fedora/pull/932) ([dchandekstark](https://github.com/dchandekstark))
- Fix issue where xml datastreams reverting after save, closes \#913 [\#931](https://github.com/samvera/active_fedora/pull/931) ([hellbunnie](https://github.com/hellbunnie))
- Avoid unnecessary loads [\#930](https://github.com/samvera/active_fedora/pull/930) ([jcoyne](https://github.com/jcoyne))
- refactor persistence spec to not use deprecated methods [\#929](https://github.com/samvera/active_fedora/pull/929) ([jcoyne](https://github.com/jcoyne))
- Create an ids\_reader for indirect containers [\#926](https://github.com/samvera/active_fedora/pull/926) ([jcoyne](https://github.com/jcoyne))
- Don't load all the members of an IndirectContainer on concat [\#925](https://github.com/samvera/active_fedora/pull/925) ([jcoyne](https://github.com/jcoyne))
- Add rubocop [\#924](https://github.com/samvera/active_fedora/pull/924) ([jcoyne](https://github.com/jcoyne))
- Save time zone information for DateTimes. Solr returns DateTimes rather than Strings. [\#923](https://github.com/samvera/active_fedora/pull/923) ([ojlyytinen](https://github.com/ojlyytinen))
- Return values for inherited attributes the same way we do for properties [\#922](https://github.com/samvera/active_fedora/pull/922) ([awead](https://github.com/awead))
- Load create\_date and modified\_date from Solr. [\#921](https://github.com/samvera/active_fedora/pull/921) ([ojlyytinen](https://github.com/ojlyytinen))
- Adds ActiveFedora::Checksum class to encapsulate file digest info. [\#919](https://github.com/samvera/active_fedora/pull/919) ([dchandekstark](https://github.com/dchandekstark))
- Append val to solr array instead of replacing when appropriate. [\#918](https://github.com/samvera/active_fedora/pull/918) ([hackmastera](https://github.com/hackmastera))
- Adds `\#create\_date` attribute method to File. [\#917](https://github.com/samvera/active_fedora/pull/917) ([dchandekstark](https://github.com/dchandekstark))

## [v9.5.0](https://github.com/samvera/active_fedora/tree/v9.5.0) (2015-10-16)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.4.3...v9.5.0)

**Closed issues:**

- When query with nil value should always return an empty relation [\#910](https://github.com/samvera/active_fedora/issues/910)
- Create wiki page for migration strategy from AF 8 to 9 [\#895](https://github.com/samvera/active_fedora/issues/895)

**Merged pull requests:**

- query for nil creates correct query [\#912](https://github.com/samvera/active_fedora/pull/912) ([jcoyne](https://github.com/jcoyne))
- Support both Fedora and Premis predicates, supports Fedora 4.4 [\#911](https://github.com/samvera/active_fedora/pull/911) ([awead](https://github.com/awead))
- AssociationHash - alias `\#include?` to `\#key?` [\#907](https://github.com/samvera/active_fedora/pull/907) ([dchandekstark](https://github.com/dchandekstark))
- Fixed syntax error in raise statement [\#906](https://github.com/samvera/active_fedora/pull/906) ([dchandekstark](https://github.com/dchandekstark))
- Let autoload do its thing [\#904](https://github.com/samvera/active_fedora/pull/904) ([jcoyne](https://github.com/jcoyne))
- Allow for sub RDF Sources via contains [\#901](https://github.com/samvera/active_fedora/pull/901) ([tpendragon](https://github.com/tpendragon))

## [v9.4.3](https://github.com/samvera/active_fedora/tree/v9.4.3) (2015-09-30)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.4.2...v9.4.3)

**Closed issues:**

- Tests failing and other problems due an update in rdf-vocab. [\#894](https://github.com/samvera/active_fedora/issues/894)

**Merged pull requests:**

- Don't mark an attribute as changed if it's set to the same value [\#902](https://github.com/samvera/active_fedora/pull/902) ([jcoyne](https://github.com/jcoyne))

## [v9.4.2](https://github.com/samvera/active_fedora/tree/v9.4.2) (2015-09-25)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.4.1...v9.4.2)

**Merged pull requests:**

- Don't skip reject\_if when \_destroy is passed [\#900](https://github.com/samvera/active_fedora/pull/900) ([jcoyne](https://github.com/jcoyne))
- Don't use Fcrepo digest predicate from rdf-vocab [\#899](https://github.com/samvera/active_fedora/pull/899) ([jcoyne](https://github.com/jcoyne))
- Updating documentation of Indexing Service [\#898](https://github.com/samvera/active_fedora/pull/898) ([jeremyf](https://github.com/jeremyf))
- Moving a method to protected [\#897](https://github.com/samvera/active_fedora/pull/897) ([jeremyf](https://github.com/jeremyf))
- Add high-level comment for Indexing module. [\#896](https://github.com/samvera/active_fedora/pull/896) ([hackmastera](https://github.com/hackmastera))
- Refactor nested\_attribute\_spec [\#893](https://github.com/samvera/active_fedora/pull/893) ([jcoyne](https://github.com/jcoyne))

## [v9.4.1](https://github.com/samvera/active_fedora/tree/v9.4.1) (2015-09-18)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.4.0...v9.4.1)

**Merged pull requests:**

- Update ldp gem to 0.4.0. [\#892](https://github.com/samvera/active_fedora/pull/892) ([jcoyne](https://github.com/jcoyne))

## [v9.4.0](https://github.com/samvera/active_fedora/tree/v9.4.0) (2015-09-03)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.3.0...v9.4.0)

**Fixed bugs:**

- DirectlyContainsAssociation can't exist on a node with an id shorter than 8 characters. [\#862](https://github.com/samvera/active_fedora/issues/862)

**Closed issues:**

- Should we use RDF::Vocab::Fcrepo4 instead of a local vocabulary? [\#886](https://github.com/samvera/active_fedora/issues/886)
- Don't run validator when deleteing. [\#885](https://github.com/samvera/active_fedora/issues/885)
- AF::File::Attributes should find digests atop Fedora 4.3.0 [\#883](https://github.com/samvera/active_fedora/issues/883)
- Revert "Requst Inbound Relations" [\#875](https://github.com/samvera/active_fedora/issues/875)

**Merged pull requests:**

- Don't run type validators on destroy. [\#888](https://github.com/samvera/active_fedora/pull/888) ([tpendragon](https://github.com/tpendragon))
- Using Fcrepo4 and LDP from RDF::Vocab instead of local versions [\#887](https://github.com/samvera/active_fedora/pull/887) ([escowles](https://github.com/escowles))
- Using premis:hasMessageDigest for checksum [\#884](https://github.com/samvera/active_fedora/pull/884) ([escowles](https://github.com/escowles))
- Update README to reflect dependency on Solr 4.10 [\#881](https://github.com/samvera/active_fedora/pull/881) ([pgwillia](https://github.com/pgwillia))
- Enable support for hash URIs. [\#878](https://github.com/samvera/active_fedora/pull/878) ([tpendragon](https://github.com/tpendragon))
- Stop using InboundRelationConnection [\#876](https://github.com/samvera/active_fedora/pull/876) ([jcoyne](https://github.com/jcoyne))

## [v9.3.0](https://github.com/samvera/active_fedora/tree/v9.3.0) (2015-08-07)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.2.1...v9.3.0)

**Merged pull requests:**

- Records should be able to be marshaled and loaded [\#872](https://github.com/samvera/active_fedora/pull/872) ([jcoyne](https://github.com/jcoyne))
- RDF association ids setter should handle nil [\#869](https://github.com/samvera/active_fedora/pull/869) ([jcoyne](https://github.com/jcoyne))
- Add collection\#select using block syntax. [\#868](https://github.com/samvera/active_fedora/pull/868) ([tpendragon](https://github.com/tpendragon))
- Add type validator objects to associations. [\#867](https://github.com/samvera/active_fedora/pull/867) ([tpendragon](https://github.com/tpendragon))

## [v9.2.1](https://github.com/samvera/active_fedora/tree/v9.2.1) (2015-07-23)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.2.0...v9.2.1)

**Closed issues:**

- delete from association should only return actual deleted objects [\#864](https://github.com/samvera/active_fedora/issues/864)
- Load\_instance\_from\_solr has issues if model has properties that aren't saved in profile\_json [\#856](https://github.com/samvera/active_fedora/issues/856)
- ActiveFedora::Base.uri\_to\_id doesn't properly handle long ids [\#855](https://github.com/samvera/active_fedora/issues/855)
- ContainerProxy should respond to each\_with\_index.  [\#851](https://github.com/samvera/active_fedora/issues/851)
- Prefer quick check of id before full object check [\#849](https://github.com/samvera/active_fedora/issues/849)

**Merged pull requests:**

- Don't delete unrelated objects in Collection Association [\#866](https://github.com/samvera/active_fedora/pull/866) ([tpendragon](https://github.com/tpendragon))
- ChangeSet shouldn't record other subjects. [\#863](https://github.com/samvera/active_fedora/pull/863) ([tpendragon](https://github.com/tpendragon))
- Update unit test style [\#861](https://github.com/samvera/active_fedora/pull/861) ([jcoyne](https://github.com/jcoyne))
- Improve handling of imperfect profile\_json when loading instances from Solr. [\#860](https://github.com/samvera/active_fedora/pull/860) ([ojlyytinen](https://github.com/ojlyytinen))
- Test suite in CI should use Java 8 for Hydra-Jetty [\#854](https://github.com/samvera/active_fedora/pull/854) ([mjgiarlo](https://github.com/mjgiarlo))
- Relation should respond to enumerable methods [\#852](https://github.com/samvera/active_fedora/pull/852) ([jcoyne](https://github.com/jcoyne))

## [v9.2.0](https://github.com/samvera/active_fedora/tree/v9.2.0) (2015-07-08)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.2.0.rc2...v9.2.0)

**Merged pull requests:**

- Remove has\_many\_versions [\#846](https://github.com/samvera/active_fedora/pull/846) ([jcoyne](https://github.com/jcoyne))

## [v9.2.0.rc2](https://github.com/samvera/active_fedora/tree/v9.2.0.rc2) (2015-07-01)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.2.0.rc1...v9.2.0.rc2)

**Merged pull requests:**

- Allow the FixityService to accept an RDF::URI [\#845](https://github.com/samvera/active_fedora/pull/845) ([jcoyne](https://github.com/jcoyne))

## [v9.2.0.rc1](https://github.com/samvera/active_fedora/tree/v9.2.0.rc1) (2015-06-30)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.1.2...v9.2.0.rc1)

**Fixed bugs:**

- Can't delete Direct Container Files [\#794](https://github.com/samvera/active_fedora/issues/794)

**Closed issues:**

- ActiveFedora::File should error if a file is saved without content [\#831](https://github.com/samvera/active_fedora/issues/831)
- Associations do not allow chaining relations [\#352](https://github.com/samvera/active_fedora/issues/352)

**Merged pull requests:**

- Refactor CollectionAssociation\#reset [\#844](https://github.com/samvera/active_fedora/pull/844) ([jcoyne](https://github.com/jcoyne))
- make CollectionAssociation\#find\_target private [\#843](https://github.com/samvera/active_fedora/pull/843) ([jcoyne](https://github.com/jcoyne))
- The uri\(\) method should return an RDF::URI [\#841](https://github.com/samvera/active_fedora/pull/841) ([jcoyne](https://github.com/jcoyne))
- Refactor File\#== to avoid an unnecessary API call [\#840](https://github.com/samvera/active_fedora/pull/840) ([jcoyne](https://github.com/jcoyne))
- Use the solr terms query when fetching by id [\#839](https://github.com/samvera/active_fedora/pull/839) ([jcoyne](https://github.com/jcoyne))
- Allow File constructor to take a block. [\#838](https://github.com/samvera/active_fedora/pull/838) ([jcoyne](https://github.com/jcoyne))
- Avoid unnecessary solr query [\#837](https://github.com/samvera/active_fedora/pull/837) ([jcoyne](https://github.com/jcoyne))
- For an AF record the primary key is always `id` [\#836](https://github.com/samvera/active_fedora/pull/836) ([jcoyne](https://github.com/jcoyne))
- Save method has been updated to be inline with Rails and return boolean... [\#834](https://github.com/samvera/active_fedora/pull/834) ([hectorcorrea](https://github.com/hectorcorrea))
- Implements delete for direct containers. [\#832](https://github.com/samvera/active_fedora/pull/832) ([hectorcorrea](https://github.com/hectorcorrea))
- RDF::IndexingService indexes objects & properties [\#830](https://github.com/samvera/active_fedora/pull/830) ([awead](https://github.com/awead))
- Reorganizing ActiveFedora:File code [\#829](https://github.com/samvera/active_fedora/pull/829) ([awead](https://github.com/awead))
- Make autosave tests more specific [\#828](https://github.com/samvera/active_fedora/pull/828) ([awead](https://github.com/awead))
- Use foreign\_key in case user has specified one [\#827](https://github.com/samvera/active_fedora/pull/827) ([awead](https://github.com/awead))
- Removing unneeded line [\#825](https://github.com/samvera/active_fedora/pull/825) ([carolyncole](https://github.com/carolyncole))
- refactoring equals for readability  [\#824](https://github.com/samvera/active_fedora/pull/824) ([carolyncole](https://github.com/carolyncole))
- Refactoring ActiveFedora::File to use ActiveFedora::Persistence [\#823](https://github.com/samvera/active_fedora/pull/823) ([carolyncole](https://github.com/carolyncole))
- Removing dead define\_destroy\_hook method [\#822](https://github.com/samvera/active_fedora/pull/822) ([awead](https://github.com/awead))
- Refactoring .find\_target for HasAndBelongsToMany [\#819](https://github.com/samvera/active_fedora/pull/819) ([awead](https://github.com/awead))
- Return relation for .limit, fixes \#352 [\#818](https://github.com/samvera/active_fedora/pull/818) ([awead](https://github.com/awead))
- Refactoring DelegatedAttribute [\#817](https://github.com/samvera/active_fedora/pull/817) ([awead](https://github.com/awead))
- \(Needs Review\) implements directly\_contains\_one association [\#816](https://github.com/samvera/active_fedora/pull/816) ([flyingzumwalt](https://github.com/flyingzumwalt))
- Forward port changes from the 9.1-stable branch. [\#814](https://github.com/samvera/active_fedora/pull/814) ([jcoyne](https://github.com/jcoyne))
- Create a blacklist to disallow mutating relations [\#812](https://github.com/samvera/active_fedora/pull/812) ([jcoyne](https://github.com/jcoyne))
- Remove unnecessary dependency on rdf-vocab [\#808](https://github.com/samvera/active_fedora/pull/808) ([jcoyne](https://github.com/jcoyne))
- Add apply\_schema support to AF. [\#807](https://github.com/samvera/active_fedora/pull/807) ([tpendragon](https://github.com/tpendragon))
- Direct/Indirect containers should have an include? method [\#806](https://github.com/samvera/active_fedora/pull/806) ([jcoyne](https://github.com/jcoyne))
- A SolrBackedResource should be enumerable [\#804](https://github.com/samvera/active_fedora/pull/804) ([jcoyne](https://github.com/jcoyne))
- Translation procs should not overwrite one another [\#803](https://github.com/samvera/active_fedora/pull/803) ([jcoyne](https://github.com/jcoyne))
- Replace Service Object for OO Deletes [\#802](https://github.com/samvera/active_fedora/pull/802) ([tpendragon](https://github.com/tpendragon))
- Indirect container delete bug [\#801](https://github.com/samvera/active_fedora/pull/801) ([tpendragon](https://github.com/tpendragon))
- Update ActiveTriples [\#798](https://github.com/samvera/active_fedora/pull/798) ([tpendragon](https://github.com/tpendragon))
- Delete Indirect Proxies [\#796](https://github.com/samvera/active_fedora/pull/796) ([tpendragon](https://github.com/tpendragon))
- Add direct containers [\#788](https://github.com/samvera/active_fedora/pull/788) ([jcoyne](https://github.com/jcoyne))
- Add optional prefix to resource URI [\#780](https://github.com/samvera/active_fedora/pull/780) ([awead](https://github.com/awead))

## [v9.1.2](https://github.com/samvera/active_fedora/tree/v9.1.2) (2015-06-11)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v8.1.0...v9.1.2)

**Merged pull requests:**

- Track type as a changed attribute in MetadataNode [\#787](https://github.com/samvera/active_fedora/pull/787) ([jcoyne](https://github.com/jcoyne))
- File\#save should return true if there is nothing to save [\#785](https://github.com/samvera/active_fedora/pull/785) ([jcoyne](https://github.com/jcoyne))
- CollectionAssociation should generate a solr query lazily [\#783](https://github.com/samvera/active_fedora/pull/783) ([jcoyne](https://github.com/jcoyne))

## [v8.1.0](https://github.com/samvera/active_fedora/tree/v8.1.0) (2015-05-18)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.1.1...v8.1.0)

**Closed issues:**

- Delete on indirect container [\#800](https://github.com/samvera/active_fedora/issues/800)
- Can't delete Indirect Container proxies. [\#793](https://github.com/samvera/active_fedora/issues/793)
- Allow rdf:type on ActiveFedora::File [\#792](https://github.com/samvera/active_fedora/issues/792)
- File should save metadata changes even if content is unchanged [\#784](https://github.com/samvera/active_fedora/issues/784)
- The contains method should use LDP and use the /files/ container [\#714](https://github.com/samvera/active_fedora/issues/714)
- Use LDP for membership [\#713](https://github.com/samvera/active_fedora/issues/713)

**Merged pull requests:**

- Added ldp:IndirectContainer [\#790](https://github.com/samvera/active_fedora/pull/790) ([jcoyne](https://github.com/jcoyne))
- Version 8.1.0 [\#779](https://github.com/samvera/active_fedora/pull/779) ([dchandekstark](https://github.com/dchandekstark))
- Patches casting behavior [\#777](https://github.com/samvera/active_fedora/pull/777) ([dchandekstark](https://github.com/dchandekstark))

## [v9.1.1](https://github.com/samvera/active_fedora/tree/v9.1.1) (2015-04-17)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.1.0...v9.1.1)

**Merged pull requests:**

- properties delegated to xml files should be able to be singular [\#773](https://github.com/samvera/active_fedora/pull/773) ([jcoyne](https://github.com/jcoyne))

## [v9.1.0](https://github.com/samvera/active_fedora/tree/v9.1.0) (2015-04-16)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.1.0.rc1...v9.1.0)

**Closed issues:**

- `title` property does not delegate correctly. [\#769](https://github.com/samvera/active_fedora/issues/769)

**Merged pull requests:**

- Use delegate\_to instead of datastream in the options for property [\#772](https://github.com/samvera/active_fedora/pull/772) ([jcoyne](https://github.com/jcoyne))

## [v9.1.0.rc1](https://github.com/samvera/active_fedora/tree/v9.1.0.rc1) (2015-04-15)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.0.7...v9.1.0.rc1)

**Closed issues:**

- HasAndBelongsToManyAssociation\#delete\_records assumes the inverse is a HABTM [\#763](https://github.com/samvera/active_fedora/issues/763)
- RuntimeError when saveing HABTM [\#760](https://github.com/samvera/active_fedora/issues/760)
- has\_and\_belongs\_to\_many build is not persising the relationship [\#752](https://github.com/samvera/active_fedora/issues/752)

**Merged pull requests:**

- Requires 'deprecation' for ActiveFedora::File [\#766](https://github.com/samvera/active_fedora/pull/766) ([afred](https://github.com/afred))
- Make \#translate\_id\_to\_uri/uri\_to\_id reliable. [\#765](https://github.com/samvera/active_fedora/pull/765) ([tpendragon](https://github.com/tpendragon))
- The indexing hints should be inheritable \(backport from master\) [\#762](https://github.com/samvera/active_fedora/pull/762) ([jcoyne](https://github.com/jcoyne))
- Fix inverse of has many [\#761](https://github.com/samvera/active_fedora/pull/761) ([jcoyne](https://github.com/jcoyne))
- Content model inheritance [\#758](https://github.com/samvera/active_fedora/pull/758) ([stkenny](https://github.com/stkenny))
- Only set/save the inverse on a HABTM if the inverse is also HABTM [\#757](https://github.com/samvera/active_fedora/pull/757) ([jcoyne](https://github.com/jcoyne))
- Derive a foreign\_key ending with `\_ids` if the inverse is a collection [\#756](https://github.com/samvera/active_fedora/pull/756) ([jcoyne](https://github.com/jcoyne))
- Raise an error when the inverse relationship can not be found. [\#755](https://github.com/samvera/active_fedora/pull/755) ([jcoyne](https://github.com/jcoyne))
- Refactor has\_and\_belongs\_to\_many\_associations\_spec [\#754](https://github.com/samvera/active_fedora/pull/754) ([jcoyne](https://github.com/jcoyne))
- Remove unused sample classes [\#753](https://github.com/samvera/active_fedora/pull/753) ([jcoyne](https://github.com/jcoyne))
- Clean Connection [\#750](https://github.com/samvera/active_fedora/pull/750) ([tpendragon](https://github.com/tpendragon))
- Sort versions as dates not as strings [\#749](https://github.com/samvera/active_fedora/pull/749) ([mjgiarlo](https://github.com/mjgiarlo))
- The indexing hints should be inheritable [\#748](https://github.com/samvera/active_fedora/pull/748) ([jcoyne](https://github.com/jcoyne))
- Add a mechanism to set rdf\_label on the ActiveTriple resource [\#747](https://github.com/samvera/active_fedora/pull/747) ([jcoyne](https://github.com/jcoyne))
- Prevents an object from being loaded to the incorrect class.  [\#745](https://github.com/samvera/active_fedora/pull/745) ([hectorcorrea](https://github.com/hectorcorrea))
- Allow property to delegate to a datastream. Ref \#736 [\#744](https://github.com/samvera/active_fedora/pull/744) ([jcoyne](https://github.com/jcoyne))
- Move the indexing logic to the model. Fixes \#736 [\#743](https://github.com/samvera/active_fedora/pull/743) ([jcoyne](https://github.com/jcoyne))

## [v9.0.7](https://github.com/samvera/active_fedora/tree/v9.0.7) (2015-04-07)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v8.0.1...v9.0.7)

**Closed issues:**

- Make RDF and XML attribute definition syntax consistent [\#736](https://github.com/samvera/active_fedora/issues/736)

**Merged pull requests:**

- Backport fixes to 9.0-stable [\#759](https://github.com/samvera/active_fedora/pull/759) ([jcoyne](https://github.com/jcoyne))

## [v8.0.1](https://github.com/samvera/active_fedora/tree/v8.0.1) (2015-03-27)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.0.6...v8.0.1)

**Merged pull requests:**

- Backport solr escape patch [\#726](https://github.com/samvera/active_fedora/pull/726) ([cjcolvar](https://github.com/cjcolvar))

## [v9.0.6](https://github.com/samvera/active_fedora/tree/v9.0.6) (2015-03-27)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.0.5...v9.0.6)

**Closed issues:**

- property\_config nil after setting type [\#737](https://github.com/samvera/active_fedora/issues/737)

**Merged pull requests:**

- Setting type should not wipe out properties. Fixes \#737 [\#738](https://github.com/samvera/active_fedora/pull/738) ([jcoyne](https://github.com/jcoyne))

## [v9.0.5](https://github.com/samvera/active_fedora/tree/v9.0.5) (2015-03-26)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.0.4...v9.0.5)

**Closed issues:**

- File\#default\_attributes doesn't seem to be used. Remove it. [\#732](https://github.com/samvera/active_fedora/issues/732)
- Deprecate attach\_file, add\_file can do the same and more. [\#728](https://github.com/samvera/active_fedora/issues/728)

**Merged pull requests:**

- Properties named \*\_id should not break the change set [\#735](https://github.com/samvera/active_fedora/pull/735) ([cjcolvar](https://github.com/cjcolvar))
- Add rdf:type assertions to ActiveFedora::Base [\#734](https://github.com/samvera/active_fedora/pull/734) ([jcoyne](https://github.com/jcoyne))
- Remove \#default\_attributes. Fixes \#732 [\#733](https://github.com/samvera/active_fedora/pull/733) ([cjcolvar](https://github.com/cjcolvar))
- Make sure datastreams get configured on load as well as new/create [\#730](https://github.com/samvera/active_fedora/pull/730) ([mbklein](https://github.com/mbklein))
- Allow a has\_many association to specify an explicit foreign key via the :as option [\#729](https://github.com/samvera/active_fedora/pull/729) ([mbklein](https://github.com/mbklein))

## [v9.0.4](https://github.com/samvera/active_fedora/tree/v9.0.4) (2015-03-11)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.0.3...v9.0.4)

**Merged pull requests:**

- Refactor the AF::Base initializer [\#725](https://github.com/samvera/active_fedora/pull/725) ([jcoyne](https://github.com/jcoyne))
- Added missing id setter [\#724](https://github.com/samvera/active_fedora/pull/724) ([jcoyne](https://github.com/jcoyne))

## [v9.0.3](https://github.com/samvera/active_fedora/tree/v9.0.3) (2015-03-06)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.0.2...v9.0.3)

**Closed issues:**

- RSolr.escape is deprecated [\#721](https://github.com/samvera/active_fedora/issues/721)
- Support basic authorization to Fedora [\#716](https://github.com/samvera/active_fedora/issues/716)

**Merged pull requests:**

- Encapsulate solr\_escape and make it private [\#723](https://github.com/samvera/active_fedora/pull/723) ([jcoyne](https://github.com/jcoyne))
- Use modified RSolr.solr\_escape method [\#722](https://github.com/samvera/active_fedora/pull/722) ([awead](https://github.com/awead))

## [v9.0.2](https://github.com/samvera/active_fedora/tree/v9.0.2) (2015-02-24)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.0.1...v9.0.2)

**Closed issues:**

- Opitimize HTTP interaction with Fedora 4 [\#493](https://github.com/samvera/active_fedora/issues/493)

**Merged pull requests:**

- Jettywrapper doesn't require hydra\_jetty\_version [\#719](https://github.com/samvera/active_fedora/pull/719) ([awead](https://github.com/awead))
- Support basic authorization to Fedora [\#717](https://github.com/samvera/active_fedora/pull/717) ([awead](https://github.com/awead))
- Provide more documentation around delete and destroy \[ci skip\] [\#715](https://github.com/samvera/active_fedora/pull/715) ([jcoyne](https://github.com/jcoyne))
- Avoid unnecessary HEAD request on file retrieval. Fixes \#493 [\#711](https://github.com/samvera/active_fedora/pull/711) ([jcoyne](https://github.com/jcoyne))

## [v9.0.1](https://github.com/samvera/active_fedora/tree/v9.0.1) (2015-02-10)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.0.0...v9.0.1)

**Merged pull requests:**

- Speed up the first load if there are lots of objects in the graph [\#712](https://github.com/samvera/active_fedora/pull/712) ([jcoyne](https://github.com/jcoyne))

## [v9.0.0](https://github.com/samvera/active_fedora/tree/v9.0.0) (2015-01-30)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.0.0.rc3...v9.0.0)

**Implemented enhancements:**

- should stream large files to fedora instead of loading the file completely into memory before sending [\#700](https://github.com/samvera/active_fedora/issues/700)

**Fixed bugs:**

- Bug in LDP when retrieving a NonRDFSource [\#704](https://github.com/samvera/active_fedora/issues/704)
- load\_instance\_from\_solr causes an LDP load. [\#698](https://github.com/samvera/active_fedora/issues/698)

**Closed issues:**

- quotes in filenames should be escaped [\#693](https://github.com/samvera/active_fedora/issues/693)
- If base\_path isn't set then Object.URI is wrong. [\#680](https://github.com/samvera/active_fedora/issues/680)
- There should be a warning if you specify two properties that share the same predicate. [\#662](https://github.com/samvera/active_fedora/issues/662)
- If base\_path is not set in fedora.yml, auto-casting doesn't work in ActiveFedora::Base.find [\#657](https://github.com/samvera/active_fedora/issues/657)

**Merged pull requests:**

- When save! is called only validate once [\#710](https://github.com/samvera/active_fedora/pull/710) ([jcoyne](https://github.com/jcoyne))
- Add 'eradicate' option to ActiveFedora::Base\#destroy [\#709](https://github.com/samvera/active_fedora/pull/709) ([mjgiarlo](https://github.com/mjgiarlo))
- Deprecate the three and four arg constructor to add\_file [\#708](https://github.com/samvera/active_fedora/pull/708) ([jcoyne](https://github.com/jcoyne))
- File\#stream should return a FileBody object [\#707](https://github.com/samvera/active_fedora/pull/707) ([jcoyne](https://github.com/jcoyne))
- Deprecate File\#add\_file\_datastream and the dsid parameter [\#706](https://github.com/samvera/active_fedora/pull/706) ([jcoyne](https://github.com/jcoyne))
- File\#last\_modified removed [\#703](https://github.com/samvera/active_fedora/pull/703) ([jcoyne](https://github.com/jcoyne))
- Don't read streams into a string before saving [\#701](https://github.com/samvera/active_fedora/pull/701) ([jcoyne](https://github.com/jcoyne))
- Encodes file name in HTTP header to allow for special characters in filename [\#699](https://github.com/samvera/active_fedora/pull/699) ([hectorcorrea](https://github.com/hectorcorrea))
- Caching [\#697](https://github.com/samvera/active_fedora/pull/697) ([jcoyne](https://github.com/jcoyne))
- Fixes bug that prevented ActiveFedora from deserializing classes  [\#696](https://github.com/samvera/active_fedora/pull/696) ([hectorcorrea](https://github.com/hectorcorrea))
- Removed ActiveFedora::RDF::RelsExt [\#695](https://github.com/samvera/active_fedora/pull/695) ([jcoyne](https://github.com/jcoyne))
- Load singular datastream attributes from solr [\#694](https://github.com/samvera/active_fedora/pull/694) ([jcoyne](https://github.com/jcoyne))
- Jetty should wait a bit longer before unblocking [\#692](https://github.com/samvera/active_fedora/pull/692) ([mjgiarlo](https://github.com/mjgiarlo))

## [v9.0.0.rc3](https://github.com/samvera/active_fedora/tree/v9.0.0.rc3) (2015-01-16)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v8.0.0...v9.0.0.rc3)

**Merged pull requests:**

- Use Fcrepo4 class repository definitions [\#691](https://github.com/samvera/active_fedora/pull/691) ([awead](https://github.com/awead))
- Pass nested attribute options to the resource [\#689](https://github.com/samvera/active_fedora/pull/689) ([jcoyne](https://github.com/jcoyne))
- Upgrade ActiveTriples to 0.6.0 [\#688](https://github.com/samvera/active_fedora/pull/688) ([jcoyne](https://github.com/jcoyne))
- After setting nested rdf attributes, mark the attributes as changed.  [\#686](https://github.com/samvera/active_fedora/pull/686) ([jcoyne](https://github.com/jcoyne))
- Warn user when initial connection to Fedora fails and the URL does not e... [\#684](https://github.com/samvera/active_fedora/pull/684) ([hectorcorrea](https://github.com/hectorcorrea))
- Support nested attributes for RDF properties. Fixes \#682 [\#683](https://github.com/samvera/active_fedora/pull/683) ([jcoyne](https://github.com/jcoyne))
- Warn when the same predicate is used in more than one property [\#681](https://github.com/samvera/active_fedora/pull/681) ([hectorcorrea](https://github.com/hectorcorrea))
- Fix reindex\_everything. Fixes \#678 [\#679](https://github.com/samvera/active_fedora/pull/679) ([jcoyne](https://github.com/jcoyne))

## [v8.0.0](https://github.com/samvera/active_fedora/tree/v8.0.0) (2015-01-14)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v8.0.0.rc3...v8.0.0)

**Implemented enhancements:**

- Allow AF::Base properties to accept nested attributes [\#672](https://github.com/samvera/active_fedora/issues/672)

**Fixed bugs:**

- Misleading 302 error from LDP when pointing to wrong Fedora URL [\#656](https://github.com/samvera/active_fedora/issues/656)

**Closed issues:**

- Setting rdf nested attributes \(id\) should update changed attributes [\#685](https://github.com/samvera/active_fedora/issues/685)
- accept nested attributes for a property on an AF::Base object [\#682](https://github.com/samvera/active_fedora/issues/682)

**Merged pull requests:**

- Bumped version to 8.0.0 [\#687](https://github.com/samvera/active_fedora/pull/687) ([dchandekstark](https://github.com/dchandekstark))

## [v8.0.0.rc3](https://github.com/samvera/active_fedora/tree/v8.0.0.rc3) (2015-01-07)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.0.0.rc2...v8.0.0.rc3)

**Closed issues:**

- Reindex\_everything  raising error [\#678](https://github.com/samvera/active_fedora/issues/678)
- Code tidying [\#636](https://github.com/samvera/active_fedora/issues/636)

**Merged pull requests:**

- Can assign single ActiveTriples::Resource to single-valued attribute \(fi... [\#676](https://github.com/samvera/active_fedora/pull/676) ([dchandekstark](https://github.com/dchandekstark))
- github issue 48 tests and YARD [\#629](https://github.com/samvera/active_fedora/pull/629) ([barmintor](https://github.com/barmintor))

## [v9.0.0.rc2](https://github.com/samvera/active_fedora/tree/v9.0.0.rc2) (2015-01-07)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.0.0.rc1...v9.0.0.rc2)

**Merged pull requests:**

- Use the File class in the root namespace [\#677](https://github.com/samvera/active_fedora/pull/677) ([jcoyne](https://github.com/jcoyne))

## [v9.0.0.rc1](https://github.com/samvera/active_fedora/tree/v9.0.0.rc1) (2015-01-07)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.0.0.beta8...v9.0.0.rc1)

**Closed issues:**

- active\_fedora:model generator needs update for ActiveFedora 9 [\#665](https://github.com/samvera/active_fedora/issues/665)
- Incorporate Solrizer into ActiveFedora, It doesn't really have a purpose all alone. [\#664](https://github.com/samvera/active_fedora/issues/664)
- Add sanitize\_for\_mass\_assignment to attributes= [\#658](https://github.com/samvera/active_fedora/issues/658)
- Option to refresh versions cache [\#641](https://github.com/samvera/active_fedora/issues/641)
- Explicitly sort versions according to creation date [\#640](https://github.com/samvera/active_fedora/issues/640)

**Merged pull requests:**

- Test on rails 4.2 and Ruby 2.2 [\#675](https://github.com/samvera/active_fedora/pull/675) ([jcoyne](https://github.com/jcoyne))
- Remove cucumber from the solr template [\#674](https://github.com/samvera/active_fedora/pull/674) ([jcoyne](https://github.com/jcoyne))
- Create an indexing service for RDF properties [\#673](https://github.com/samvera/active_fedora/pull/673) ([jcoyne](https://github.com/jcoyne))
- Renamed Base.get\_descendent\_uris to Base.descendent\_uris [\#671](https://github.com/samvera/active_fedora/pull/671) ([jcoyne](https://github.com/jcoyne))
- Provide the URI as part of the error message when object recreation is a... [\#670](https://github.com/samvera/active_fedora/pull/670) ([jcoyne](https://github.com/jcoyne))
- Generate tests for model with RDF predicates [\#668](https://github.com/samvera/active_fedora/pull/668) ([jcoyne](https://github.com/jcoyne))
- Updates to model generator templates for latest version of rspec-rails [\#667](https://github.com/samvera/active_fedora/pull/667) ([jcoyne](https://github.com/jcoyne))
- Update the model generator. Fixes \#665 [\#666](https://github.com/samvera/active_fedora/pull/666) ([jcoyne](https://github.com/jcoyne))
- reindex\_everything should ignore non-RDF sources [\#663](https://github.com/samvera/active_fedora/pull/663) ([jcoyne](https://github.com/jcoyne))
- IndexingService\#generate\_solr\_document should yield the solr document [\#661](https://github.com/samvera/active_fedora/pull/661) ([jcoyne](https://github.com/jcoyne))
- Restore the generator for fedora.yml [\#660](https://github.com/samvera/active_fedora/pull/660) ([jcoyne](https://github.com/jcoyne))

## [v9.0.0.beta8](https://github.com/samvera/active_fedora/tree/v9.0.0.beta8) (2014-12-19)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.0.0.beta7...v9.0.0.beta8)

**Fixed bugs:**

- STATUS: 409 Could not remove triple when running ActiveFedora::Cleaner.clean! [\#647](https://github.com/samvera/active_fedora/issues/647)

**Closed issues:**

- Indexing should have a class for building the profile and not rely on to\_json [\#654](https://github.com/samvera/active_fedora/issues/654)
- LoadableFromJson should filter json attributes [\#648](https://github.com/samvera/active_fedora/issues/648)

**Merged pull requests:**

- Add strong parameters validation [\#659](https://github.com/samvera/active_fedora/pull/659) ([jcoyne](https://github.com/jcoyne))
- Add a service object for indexing profile json documents [\#655](https://github.com/samvera/active_fedora/pull/655) ([jcoyne](https://github.com/jcoyne))
- fixes \#648 Bug: LoadableFromJson raises error when you have extra fields... [\#652](https://github.com/samvera/active_fedora/pull/652) ([flyingzumwalt](https://github.com/flyingzumwalt))
- Reload and sort versions [\#650](https://github.com/samvera/active_fedora/pull/650) ([awead](https://github.com/awead))
- Raise an error if data could be lost from singularizing a list [\#649](https://github.com/samvera/active_fedora/pull/649) ([jcoyne](https://github.com/jcoyne))

## [v9.0.0.beta7](https://github.com/samvera/active_fedora/tree/v9.0.0.beta7) (2014-12-11)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.0.0.beta6...v9.0.0.beta7)

**Closed issues:**

- CollectionAssociation\#ids\_reader does not cache results, reads from solr each time. [\#644](https://github.com/samvera/active_fedora/issues/644)

**Merged pull requests:**

- Bump ldp dependency to 0.2 [\#646](https://github.com/samvera/active_fedora/pull/646) ([jcoyne](https://github.com/jcoyne))
- PERF: Don't query solr again if we know there will be no results [\#645](https://github.com/samvera/active_fedora/pull/645) ([jcoyne](https://github.com/jcoyne))
- Single valued properties accessed via the Hash accessor should be singular [\#643](https://github.com/samvera/active_fedora/pull/643) ([jcoyne](https://github.com/jcoyne))

## [v9.0.0.beta6](https://github.com/samvera/active_fedora/tree/v9.0.0.beta6) (2014-12-08)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.0.0.beta5...v9.0.0.beta6)

**Implemented enhancements:**

- Define unique?\(key\) method [\#637](https://github.com/samvera/active_fedora/issues/637)

**Merged pull requests:**

- Enable single-value rdf fields withought depending on ActiveTriples [\#638](https://github.com/samvera/active_fedora/pull/638) ([jcoyne](https://github.com/jcoyne))

## [v9.0.0.beta5](https://github.com/samvera/active_fedora/tree/v9.0.0.beta5) (2014-12-06)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.0.0.beta4...v9.0.0.beta5)

**Merged pull requests:**

- Support indexing single value RDF properties [\#635](https://github.com/samvera/active_fedora/pull/635) ([jcoyne](https://github.com/jcoyne))

## [v9.0.0.beta4](https://github.com/samvera/active_fedora/tree/v9.0.0.beta4) (2014-12-05)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.0.0.beta3...v9.0.0.beta4)

**Fixed bugs:**

- Using the attribute accessor `:\[\]` method should return nil for terms that are singular [\#631](https://github.com/samvera/active_fedora/issues/631)

**Closed issues:**

- Single-valued properties [\#632](https://github.com/samvera/active_fedora/issues/632)
- Refactor CollectionAssociation to use Reflection\#solr\_key [\#605](https://github.com/samvera/active_fedora/issues/605)
- Rubydora doesn't allow managed datastreams to be created with a dsLocation [\#48](https://github.com/samvera/active_fedora/issues/48)

**Merged pull requests:**

- Init the base path when the Fedora object is initialized [\#634](https://github.com/samvera/active_fedora/pull/634) ([jcoyne](https://github.com/jcoyne))
- Allow generated property methods to validate the cardinality of values. Fixes \#632 [\#633](https://github.com/samvera/active_fedora/pull/633) ([jcoyne](https://github.com/jcoyne))
- Interface for versions [\#630](https://github.com/samvera/active_fedora/pull/630) ([awead](https://github.com/awead))

## [v9.0.0.beta3](https://github.com/samvera/active_fedora/tree/v9.0.0.beta3) (2014-12-03)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v8.0.0.rc2...v9.0.0.beta3)

**Closed issues:**

- Return version urls [\#627](https://github.com/samvera/active_fedora/issues/627)
- Return strings instead of RDF::Literals [\#625](https://github.com/samvera/active_fedora/issues/625)
- Create a method ActiveFedora::Base.initialize\_root\_resource [\#623](https://github.com/samvera/active_fedora/issues/623)
- Add a RDF Vocabulary for projecthydra namespace [\#615](https://github.com/samvera/active_fedora/issues/615)
- Add isGoverenedBy to RelsExt [\#613](https://github.com/samvera/active_fedora/issues/613)

**Merged pull requests:**

- Return array of version uris [\#628](https://github.com/samvera/active_fedora/pull/628) ([awead](https://github.com/awead))
- Adds fix for content-lenght value missing for files uploaded via ActionD... [\#622](https://github.com/samvera/active_fedora/pull/622) ([hectorcorrea](https://github.com/hectorcorrea))
- Refactor lookup of solr fields Fixes \#605 [\#611](https://github.com/samvera/active_fedora/pull/611) ([jcoyne](https://github.com/jcoyne))
- Describing bugs with pending tests [\#610](https://github.com/samvera/active_fedora/pull/610) ([awead](https://github.com/awead))

## [v8.0.0.rc2](https://github.com/samvera/active_fedora/tree/v8.0.0.rc2) (2014-12-02)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v8.0.0.rc1...v8.0.0.rc2)

**Merged pull requests:**

- Removed pending deprecations omitted in 8.0.0.rc1 [\#626](https://github.com/samvera/active_fedora/pull/626) ([dchandekstark](https://github.com/dchandekstark))

## [v8.0.0.rc1](https://github.com/samvera/active_fedora/tree/v8.0.0.rc1) (2014-12-02)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.0.0.beta2...v8.0.0.rc1)

**Fixed bugs:**

- Inconsistent behavior of \#attributes= and \#attributes causes problems with AF 8.0 [\#620](https://github.com/samvera/active_fedora/issues/620)

**Closed issues:**

- AF::OmDatastream\#get\_values\_from\_solr test failure [\#621](https://github.com/samvera/active_fedora/issues/621)

**Merged pull requests:**

- Removed pending deprecations for version 8.0.0. [\#624](https://github.com/samvera/active_fedora/pull/624) ([dchandekstark](https://github.com/dchandekstark))
- Adding optional yml paramters as comments so people know they exist [\#618](https://github.com/samvera/active_fedora/pull/618) ([carolyncole](https://github.com/carolyncole))
- add RDF::Vocabulary subclasses for FCRepo3 and ProjectHydra [\#616](https://github.com/samvera/active_fedora/pull/616) ([barmintor](https://github.com/barmintor))
- Fix to make sure all values are handled as arrays [\#612](https://github.com/samvera/active_fedora/pull/612) ([hectorcorrea](https://github.com/hectorcorrea))
- Object resource [\#500](https://github.com/samvera/active_fedora/pull/500) ([no-reply](https://github.com/no-reply))

## [v9.0.0.beta2](https://github.com/samvera/active_fedora/tree/v9.0.0.beta2) (2014-11-25)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v7.1.2...v9.0.0.beta2)

**Merged pull requests:**

- Exclude auto-snapshot versions [\#619](https://github.com/samvera/active_fedora/pull/619) ([awead](https://github.com/awead))

## [v7.1.2](https://github.com/samvera/active_fedora/tree/v7.1.2) (2014-11-17)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v9.0.0.beta1...v7.1.2)

**Merged pull requests:**

- Revert "clarified a comment" [\#569](https://github.com/samvera/active_fedora/pull/569) ([awead](https://github.com/awead))
- clarified a comment [\#568](https://github.com/samvera/active_fedora/pull/568) ([bmaddy](https://github.com/bmaddy))
- Correction to comment example [\#495](https://github.com/samvera/active_fedora/pull/495) ([atz](https://github.com/atz))
- Bug \#479: Typo in XSD filename value stuck in config generator templates [\#480](https://github.com/samvera/active_fedora/pull/480) ([atz](https://github.com/atz))

## [v9.0.0.beta1](https://github.com/samvera/active_fedora/tree/v9.0.0.beta1) (2014-11-15)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v7.1.1...v9.0.0.beta1)

**Implemented enhancements:**

- Support calls to Fedora4 fixity check [\#475](https://github.com/samvera/active_fedora/issues/475)

**Fixed bugs:**

- add\_file\_datastream should check for a reflection  [\#594](https://github.com/samvera/active_fedora/issues/594)
- SparqlInsert should not group delete clauses together [\#564](https://github.com/samvera/active_fedora/issues/564)
- Missing rdf\_subject when loading from solr [\#542](https://github.com/samvera/active_fedora/issues/542)
- Fix versionable [\#506](https://github.com/samvera/active_fedora/issues/506)

**Closed issues:**

- Resolve pending versionable specs [\#599](https://github.com/samvera/active_fedora/issues/599)
- ActiveFedora::Rdf should be ActiveFedora::RDF [\#598](https://github.com/samvera/active_fedora/issues/598)
- Clean up duplication in Reflection and Builder::Association wrt `predicate` [\#597](https://github.com/samvera/active_fedora/issues/597)
- Folder table should have a `number\_of\_members` column [\#592](https://github.com/samvera/active_fedora/issues/592)
- Base constructors should take a block [\#589](https://github.com/samvera/active_fedora/issues/589)
- contains should be managed as an association. [\#579](https://github.com/samvera/active_fedora/issues/579)
- Update deprecation warnings. deprecation\_horizon should change to 10.0 [\#571](https://github.com/samvera/active_fedora/issues/571)
- Deprecate AF::Base.find when called with hash arguments. [\#561](https://github.com/samvera/active_fedora/issues/561)
- AF::File\#has\_content? should return true if a file is attached, but it's not persisted. [\#560](https://github.com/samvera/active_fedora/issues/560)
- A SolrBackedObject should not be saveable. Make it read-only.  [\#555](https://github.com/samvera/active_fedora/issues/555)
- PropertiesDatastream: Digital object is nil [\#553](https://github.com/samvera/active_fedora/issues/553)
- PropertiesDatastream.import\_url: wrong number of arguments \(0 for 1..3\) [\#552](https://github.com/samvera/active_fedora/issues/552)
- Sufia read\_groups empty [\#550](https://github.com/samvera/active_fedora/issues/550)
- Hydra::AccessControls::Permission\(\#29436440\) expected, got Array\(\#15575200\) [\#549](https://github.com/samvera/active_fedora/issues/549)
- Solr indexing error: Document is missing mandatory uniqueKey field: id [\#548](https://github.com/samvera/active_fedora/issues/548)
- Hydra::AccessControls::Permission does not have an attribute `type' [\#547](https://github.com/samvera/active_fedora/issues/547)
- Sufia file ownership test failures [\#546](https://github.com/samvera/active_fedora/issues/546)
- Undefined method `multiple' for nil:NilClass [\#545](https://github.com/samvera/active_fedora/issues/545)
- Undefined method `has\_content?' for \#\<FileContentDatastream:0x000000084eae00\> [\#544](https://github.com/samvera/active_fedora/issues/544)
- File\#has\_content? has gone missing [\#541](https://github.com/samvera/active_fedora/issues/541)
- The attributes module is not playing well with ActiveTriples [\#536](https://github.com/samvera/active_fedora/issues/536)
- Oracle branch fails in Travis [\#524](https://github.com/samvera/active_fedora/issues/524)
- load\_datastreams should not instantiate the datastreams until needed [\#521](https://github.com/samvera/active_fedora/issues/521)
- Rename ActiveFedora::Datastream -\> ActiveFedora::File [\#518](https://github.com/samvera/active_fedora/issues/518)
- do away with Persistence\#reload\_managed\_properties [\#514](https://github.com/samvera/active_fedora/issues/514)
- rename defined\_attributes to delegated\_attributes [\#513](https://github.com/samvera/active_fedora/issues/513)
- Set up coveralls [\#511](https://github.com/samvera/active_fedora/issues/511)
- Get rid of CollectionAssociation\#add\_record\_to\_target\_with\_callbacks [\#510](https://github.com/samvera/active_fedora/issues/510)
- Associations that key off class\_name are broken. [\#509](https://github.com/samvera/active_fedora/issues/509)
- Collapse has\_file\_datastream and has\_metadata into has\_datastream [\#508](https://github.com/samvera/active_fedora/issues/508)
- Test fails. Unsure of correct behavior. [\#507](https://github.com/samvera/active_fedora/issues/507)
- Only update when the object is changed [\#505](https://github.com/samvera/active_fedora/issues/505)
- Associations should use change tracking [\#504](https://github.com/samvera/active_fedora/issues/504)
- In LDP make a subclass of Ldp::HttpError for status code 410. [\#503](https://github.com/samvera/active_fedora/issues/503)
- Use fcr:metadata to assign properties to resources [\#499](https://github.com/samvera/active_fedora/issues/499)
- Remove references to fcr:content [\#498](https://github.com/samvera/active_fedora/issues/498)
- Do PUT requests with the exact modified date \(precise to a thousandth of a second\) [\#497](https://github.com/samvera/active_fedora/issues/497)
- Implement fcr:tombstone [\#496](https://github.com/samvera/active_fedora/issues/496)
- Detect ETag mismatches [\#494](https://github.com/samvera/active_fedora/issues/494)
- Refactor Base.reindex\_everything [\#492](https://github.com/samvera/active_fedora/issues/492)
- Integration with ActiveTriples 0.4.0 [\#491](https://github.com/samvera/active_fedora/issues/491)
- Call .digest on datastreams to return urn [\#489](https://github.com/samvera/active_fedora/issues/489)
- Rename property argument on associations to predicate [\#483](https://github.com/samvera/active_fedora/issues/483)
- Config generator confused about xsd\_xacml\_policy1.0 value [\#479](https://github.com/samvera/active_fedora/issues/479)
- Enable locking [\#478](https://github.com/samvera/active_fedora/issues/478)
- Should ActiveFedora::Base.destroy\_all clear Solr? [\#470](https://github.com/samvera/active_fedora/issues/470)
- On create, if we know the pid, raise an error if the node already exists. [\#409](https://github.com/samvera/active_fedora/issues/409)
- Deprecate \#pid [\#407](https://github.com/samvera/active_fedora/issues/407)
- Pull fedora config out of fedora-lens [\#404](https://github.com/samvera/active_fedora/issues/404)
- Update AF to proxy object/datastream properties, cast them to arrays, and take the first value [\#86](https://github.com/samvera/active_fedora/issues/86)

**Merged pull requests:**

- Remove counte\_cache and touch options from belongs\_to association [\#608](https://github.com/samvera/active_fedora/pull/608) ([jcoyne](https://github.com/jcoyne))
- Remove deprecated rspec should\_receive [\#607](https://github.com/samvera/active_fedora/pull/607) ([jcoyne](https://github.com/jcoyne))
- Translate property to predicate in Builder::Association [\#606](https://github.com/samvera/active_fedora/pull/606) ([jcoyne](https://github.com/jcoyne))
- Consistent use of RDF constant [\#604](https://github.com/samvera/active_fedora/pull/604) ([awead](https://github.com/awead))
- Objects loaded from Solr should be read-only. Fixes \#555 [\#603](https://github.com/samvera/active_fedora/pull/603) ([jcoyne](https://github.com/jcoyne))
- Query File for RDF.type fixes \#599 [\#602](https://github.com/samvera/active_fedora/pull/602) ([awead](https://github.com/awead))
- Extract errors to their own file. Add documentation [\#601](https://github.com/samvera/active_fedora/pull/601) ([jcoyne](https://github.com/jcoyne))
- Deprecate property, require predicate on associations. Fixes \#483 [\#600](https://github.com/samvera/active_fedora/pull/600) ([jcoyne](https://github.com/jcoyne))
- Implements Versionable.has\_versions? [\#596](https://github.com/samvera/active_fedora/pull/596) ([hectorcorrea](https://github.com/hectorcorrea))
- add\_file\_datastream should check for a reflection. Fixes \#594 [\#595](https://github.com/samvera/active_fedora/pull/595) ([jcoyne](https://github.com/jcoyne))
- FilesHash should behave like a HashWithIndifferentAccess [\#593](https://github.com/samvera/active_fedora/pull/593) ([jcoyne](https://github.com/jcoyne))
- Deprecate File.new taking a Base as an argument [\#591](https://github.com/samvera/active_fedora/pull/591) ([jcoyne](https://github.com/jcoyne))
- ActiveFedora::Base.new should yield a block. Fixes \#589 [\#590](https://github.com/samvera/active_fedora/pull/590) ([jcoyne](https://github.com/jcoyne))
- Remove Solrizer-Fedora integration [\#588](https://github.com/samvera/active_fedora/pull/588) ([jcoyne](https://github.com/jcoyne))
- Move the 'contains' logic into an association [\#587](https://github.com/samvera/active_fedora/pull/587) ([jcoyne](https://github.com/jcoyne))
- Separate the indexing concerns out of the Persistence module [\#585](https://github.com/samvera/active_fedora/pull/585) ([jcoyne](https://github.com/jcoyne))
- Create an IndexingService responsible for indexing resources [\#584](https://github.com/samvera/active_fedora/pull/584) ([jcoyne](https://github.com/jcoyne))
- Support fixity calls to Fedora [\#583](https://github.com/samvera/active_fedora/pull/583) ([awead](https://github.com/awead))
- With metadata [\#582](https://github.com/samvera/active_fedora/pull/582) ([jcoyne](https://github.com/jcoyne))
- Deprecate calling .find with hash [\#581](https://github.com/samvera/active_fedora/pull/581) ([awead](https://github.com/awead))
- Change deprecation horizon to 10.0 [\#580](https://github.com/samvera/active_fedora/pull/580) ([awead](https://github.com/awead))
- Factor out the Ldp::Orm class [\#578](https://github.com/samvera/active_fedora/pull/578) ([jcoyne](https://github.com/jcoyne))
- Removed workaround for fcrepo4/fcrepo4\#442 [\#577](https://github.com/samvera/active_fedora/pull/577) ([jcoyne](https://github.com/jcoyne))
- Don't get the HEAD of a non-existant resource [\#576](https://github.com/samvera/active_fedora/pull/576) ([jcoyne](https://github.com/jcoyne))
- Use the headers to get Content-Disposition [\#575](https://github.com/samvera/active_fedora/pull/575) ([jcoyne](https://github.com/jcoyne))
- Allow size to be nil if there is no content [\#574](https://github.com/samvera/active_fedora/pull/574) ([jcoyne](https://github.com/jcoyne))
- Remove alias\_method\_chain [\#573](https://github.com/samvera/active_fedora/pull/573) ([jcoyne](https://github.com/jcoyne))
- Files should be independent of the ActiveFedora::Base object. [\#572](https://github.com/samvera/active_fedora/pull/572) ([jcoyne](https://github.com/jcoyne))
- Changed ActiveFedora::File\#persisted\_size to simply return 0 if we're lo... [\#570](https://github.com/samvera/active_fedora/pull/570) ([afred](https://github.com/afred))
- Refactors ActiveFedora::File\#size to use two new methods, ActiveFedora::... [\#567](https://github.com/samvera/active_fedora/pull/567) ([afred](https://github.com/afred))
- ActiveTriples properties should know that they are multiple. Fixes \#547 [\#566](https://github.com/samvera/active_fedora/pull/566) ([jcoyne](https://github.com/jcoyne))
- Separate the SPARQL deletes so if one doesn't match the others still work [\#565](https://github.com/samvera/active_fedora/pull/565) ([jcoyne](https://github.com/jcoyne))
- Shifting onto a HABTM should immediately set the ids [\#563](https://github.com/samvera/active_fedora/pull/563) ([jcoyne](https://github.com/jcoyne))
- Should be able to call first on an attribute for a document loaded from Solr [\#562](https://github.com/samvera/active_fedora/pull/562) ([jcoyne](https://github.com/jcoyne))
- Adds tests for ActiveFedora::Attributes::ClassMethods.multiple? [\#559](https://github.com/samvera/active_fedora/pull/559) ([afred](https://github.com/afred))
- Make resource\_class a class method to avoid multiple declarations of Gen... [\#557](https://github.com/samvera/active_fedora/pull/557) ([jcoyne](https://github.com/jcoyne))
- load\_instance\_from\_solr should be able to handle object associations [\#556](https://github.com/samvera/active_fedora/pull/556) ([jcoyne](https://github.com/jcoyne))
- Convenience methods from Rubydora [\#554](https://github.com/samvera/active_fedora/pull/554) ([awead](https://github.com/awead))
- Refactor the associations to follow developments in ActiveRecord [\#551](https://github.com/samvera/active_fedora/pull/551) ([jcoyne](https://github.com/jcoyne))
- Create a separate resource class for each ActiveFedora::Base subclass [\#543](https://github.com/samvera/active_fedora/pull/543) ([jcoyne](https://github.com/jcoyne))
- Raise error unless orm.new? fixes \#409 [\#539](https://github.com/samvera/active_fedora/pull/539) ([awead](https://github.com/awead))
- Use a string for class property keys [\#538](https://github.com/samvera/active_fedora/pull/538) ([awead](https://github.com/awead))
- Deprecates usage of \#pid in favor of \#id. [\#537](https://github.com/samvera/active_fedora/pull/537) ([afred](https://github.com/afred))
- At0.4.0 [\#535](https://github.com/samvera/active_fedora/pull/535) ([no-reply](https://github.com/no-reply))
- Bump test grid to rails 4.2.0.beta4 [\#533](https://github.com/samvera/active_fedora/pull/533) ([jcoyne](https://github.com/jcoyne))
- The contains method can now be called with a single argument \(name\) [\#532](https://github.com/samvera/active_fedora/pull/532) ([jcoyne](https://github.com/jcoyne))
- Use the namespaced \(root\) File model in solr config generator [\#531](https://github.com/samvera/active_fedora/pull/531) ([jcoyne](https://github.com/jcoyne))
- Use .eradiate for tombstones [\#530](https://github.com/samvera/active_fedora/pull/530) ([awead](https://github.com/awead))
- Use the namespaced \(root\) File module for the model generator [\#529](https://github.com/samvera/active_fedora/pull/529) ([jcoyne](https://github.com/jcoyne))
- Use attached\_files rather than the deprecated datastreams method [\#528](https://github.com/samvera/active_fedora/pull/528) ([jcoyne](https://github.com/jcoyne))
- Rely on autosave associations when setting nested attributes [\#527](https://github.com/samvera/active_fedora/pull/527) ([jcoyne](https://github.com/jcoyne))
- On a SPARQL insert each predicate should have its own independent variable [\#526](https://github.com/samvera/active_fedora/pull/526) ([jcoyne](https://github.com/jcoyne))
- Fetch digest uri from a resource [\#523](https://github.com/samvera/active_fedora/pull/523) ([awead](https://github.com/awead))
- Grab the file name from the HEAD request now that fcrepo is fixed [\#522](https://github.com/samvera/active_fedora/pull/522) ([jcoyne](https://github.com/jcoyne))
- Rename Datastream to File. Fixes \#518 [\#520](https://github.com/samvera/active_fedora/pull/520) ([jcoyne](https://github.com/jcoyne))
- Updates to Versionable [\#519](https://github.com/samvera/active_fedora/pull/519) ([awead](https://github.com/awead))
- Extract cleanup logic from spec\_helper into ActiveFedora::Cleaner [\#517](https://github.com/samvera/active_fedora/pull/517) ([jcoyne](https://github.com/jcoyne))
- Removed unused ActiveTriples predicates [\#516](https://github.com/samvera/active_fedora/pull/516) ([jcoyne](https://github.com/jcoyne))
- Consolidate has\_metadata and has\_file\_datastream into contains. Fixes \#508 [\#515](https://github.com/samvera/active_fedora/pull/515) ([jcoyne](https://github.com/jcoyne))
- Replaces ActiveFedora::Indexing.urls\_from\_sitemap\_index with ActiveFedor... [\#512](https://github.com/samvera/active_fedora/pull/512) ([afred](https://github.com/afred))
- Remove the ContainerResource from Datastream [\#501](https://github.com/samvera/active_fedora/pull/501) ([jcoyne](https://github.com/jcoyne))
- Attribute\_names should be available via an instance method [\#488](https://github.com/samvera/active_fedora/pull/488) ([jcoyne](https://github.com/jcoyne))
- Enable create on an association to take attributes [\#487](https://github.com/samvera/active_fedora/pull/487) ([jcoyne](https://github.com/jcoyne))
- Allow polymorphic has\_many associations [\#485](https://github.com/samvera/active_fedora/pull/485) ([jcoyne](https://github.com/jcoyne))
- Remove duplicate code \(set\_belongs\_to\_association\_for\) [\#484](https://github.com/samvera/active_fedora/pull/484) ([jcoyne](https://github.com/jcoyne))
- Put the ldp dependency in the gemspec [\#482](https://github.com/samvera/active_fedora/pull/482) ([jcoyne](https://github.com/jcoyne))
- Provide a sensible default for base\_path [\#481](https://github.com/samvera/active_fedora/pull/481) ([jcoyne](https://github.com/jcoyne))
- Reimplement load\_instance\_from\_solr [\#474](https://github.com/samvera/active_fedora/pull/474) ([jcoyne](https://github.com/jcoyne))
- Restore existing versions of datastreams [\#469](https://github.com/samvera/active_fedora/pull/469) ([awead](https://github.com/awead))

## [v7.1.1](https://github.com/samvera/active_fedora/tree/v7.1.1) (2014-09-22)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v7.1.0...v7.1.1)

**Fixed bugs:**

- Calling RdfDatstream\#deserialize unexpectedly returns RubydoraRepository [\#471](https://github.com/samvera/active_fedora/issues/471)
- RDFDatastream\#content= should accept IO [\#461](https://github.com/samvera/active_fedora/issues/461)

**Closed issues:**

- NoMethodError: undefined method properties= in activetriples branch [\#466](https://github.com/samvera/active_fedora/issues/466)
- NtriplesRDFDatastream should have default mimeType "application/n-triples" [\#464](https://github.com/samvera/active_fedora/issues/464)
- SimpleDatastream:  undefined method `val' for "text/xml":String [\#459](https://github.com/samvera/active_fedora/issues/459)
- wrong number of arguments to save. [\#458](https://github.com/samvera/active_fedora/issues/458)
- Implement Range Requests for fedora 4 [\#456](https://github.com/samvera/active_fedora/issues/456)
- 500 ItemNotFoundException spec/integration/associations\_spec.rb:268 [\#414](https://github.com/samvera/active_fedora/issues/414)
- 500 NPE spec/integration/has\_and\_belongs\_to\_many\_associations\_spec.rb:43 [\#413](https://github.com/samvera/active_fedora/issues/413)
- 412 ETag mismatch [\#412](https://github.com/samvera/active_fedora/issues/412)
- Reimplment AF::Indexing.reindex\_everything as AF::Relation.index\_all [\#410](https://github.com/samvera/active_fedora/issues/410)
- Generate a new rails app that is the prototype. [\#406](https://github.com/samvera/active_fedora/issues/406)
- Branch of Sufia and dependancies that can run for AF8  [\#405](https://github.com/samvera/active_fedora/issues/405)
- Include tests and functionality from Curate [\#274](https://github.com/samvera/active_fedora/issues/274)
- Expected setting a multi-value delegate attribute to return an array [\#141](https://github.com/samvera/active_fedora/issues/141)

**Merged pull requests:**

- RdfDatastream\#deserialize should always return an RDF::Graph. Fixes \#471 [\#472](https://github.com/samvera/active_fedora/pull/472) ([jcoyne](https://github.com/jcoyne))
- Set default mimeType for NtriplesRDFDatastream to 'application/n-triples' [\#465](https://github.com/samvera/active_fedora/pull/465) ([dchandekstark](https://github.com/dchandekstark))
- RDFDatastream\#content= patched to accept IO [\#462](https://github.com/samvera/active_fedora/pull/462) ([dchandekstark](https://github.com/dchandekstark))
- Only set ds content in \#create\_datastream for managed and inline [\#460](https://github.com/samvera/active_fedora/pull/460) ([dchandekstark](https://github.com/dchandekstark))

## [v7.1.0](https://github.com/samvera/active_fedora/tree/v7.1.0) (2014-07-18)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.7.8...v7.1.0)

**Closed issues:**

- Appending to RDF List doesn't remove the nil \#rest assertion [\#445](https://github.com/samvera/active_fedora/issues/445)
- Dependency Conflict for RSpec [\#437](https://github.com/samvera/active_fedora/issues/437)

**Merged pull requests:**

- Update Om and Rubydora depencencies [\#454](https://github.com/samvera/active_fedora/pull/454) ([jcoyne](https://github.com/jcoyne))
- Change the deprecation message so that it helps you find the problem [\#453](https://github.com/samvera/active_fedora/pull/453) ([jcoyne](https://github.com/jcoyne))
- Make logger an accessor that can be set [\#450](https://github.com/samvera/active_fedora/pull/450) ([jcoyne](https://github.com/jcoyne))
- Remove mediashelf-loggable [\#449](https://github.com/samvera/active_fedora/pull/449) ([jcoyne](https://github.com/jcoyne))
- Refactoring ActiveFedora::Rdf to use ActiveTriples [\#447](https://github.com/samvera/active_fedora/pull/447) ([no-reply](https://github.com/no-reply))
- Add solr\_page\_size as a valid option for HABTM [\#443](https://github.com/samvera/active_fedora/pull/443) ([jcoyne](https://github.com/jcoyne))
- Fixes YAML serialization issues [\#440](https://github.com/samvera/active_fedora/pull/440) ([mbklein](https://github.com/mbklein))
- Refactor for style/readability [\#438](https://github.com/samvera/active_fedora/pull/438) ([jcoyne](https://github.com/jcoyne))
- Fixed bug in ActiveFedora::FinderMethods\#load\_from\_fedora  [\#434](https://github.com/samvera/active_fedora/pull/434) ([dchandekstark](https://github.com/dchandekstark))
- Adds :update\_index option to `save' [\#433](https://github.com/samvera/active_fedora/pull/433) ([dchandekstark](https://github.com/dchandekstark))
- Created pid instance variable so value can be retained after destroy [\#430](https://github.com/samvera/active_fedora/pull/430) ([dchandekstark](https://github.com/dchandekstark))
- Added support to `exists?' finder method for a hash of conditions [\#429](https://github.com/samvera/active_fedora/pull/429) ([dchandekstark](https://github.com/dchandekstark))
- Deprecate confusing attribute setter behaviors [\#428](https://github.com/samvera/active_fedora/pull/428) ([dchandekstark](https://github.com/dchandekstark))

## [v6.7.8](https://github.com/samvera/active_fedora/tree/v6.7.8) (2014-06-25)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v7.0.4...v6.7.8)

**Fixed bugs:**

- find\_each doesn't cast AF::Base by default  [\#431](https://github.com/samvera/active_fedora/issues/431)
- destroy should not clear the object's pid [\#422](https://github.com/samvera/active_fedora/issues/422)

**Closed issues:**

- ActiveFedora::DatastreamHash cannot be deserialized from YAML [\#439](https://github.com/samvera/active_fedora/issues/439)
- Finder method `exists?' should accept hash conditions [\#427](https://github.com/samvera/active_fedora/issues/427)

**Merged pull requests:**

- Backport 58b9e7e and 3a946ff to 6.7 [\#442](https://github.com/samvera/active_fedora/pull/442) ([mbklein](https://github.com/mbklein))

## [v7.0.4](https://github.com/samvera/active_fedora/tree/v7.0.4) (2014-06-10)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v7.0.3...v7.0.4)

**Closed issues:**

- Collection association finder doesn't respect where values. [\#423](https://github.com/samvera/active_fedora/issues/423)

**Merged pull requests:**

- Adding start/offset option for queries [\#421](https://github.com/samvera/active_fedora/pull/421) ([no-reply](https://github.com/no-reply))
- Add \#any? for Rspec 3 support [\#420](https://github.com/samvera/active_fedora/pull/420) ([cjcolvar](https://github.com/cjcolvar))

## [v7.0.3](https://github.com/samvera/active_fedora/tree/v7.0.3) (2014-05-13)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v7.0.2...v7.0.3)

**Fixed bugs:**

- construct\_query\_for\_pids called with a string instead of an array [\#418](https://github.com/samvera/active_fedora/issues/418)

**Closed issues:**

- 412 ETag mismatch [\#411](https://github.com/samvera/active_fedora/issues/411)
- Fix reindex\_everything [\#401](https://github.com/samvera/active_fedora/issues/401)
- Content-Length not given and Transfer-Encoding is not `chunked' [\#397](https://github.com/samvera/active_fedora/issues/397)

**Merged pull requests:**

- Remove invalid call to construct\_query\_for\_pids. Reduced total number of... [\#419](https://github.com/samvera/active_fedora/pull/419) ([jcoyne](https://github.com/jcoyne))
- Define ActiveFedora::Rollback so it can be used in AutosaveAssociation [\#416](https://github.com/samvera/active_fedora/pull/416) ([cjcolvar](https://github.com/cjcolvar))
- \#association\(name\) should return nil if no association is found [\#415](https://github.com/samvera/active_fedora/pull/415) ([cjcolvar](https://github.com/cjcolvar))

## [v7.0.2](https://github.com/samvera/active_fedora/tree/v7.0.2) (2014-04-17)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v7.0.1...v7.0.2)

**Fixed bugs:**

- HasManyAssociation\#count\_records NameError [\#383](https://github.com/samvera/active_fedora/issues/383)

**Closed issues:**

- Setting non-existent attributes with RDF nested attributes fails silently [\#393](https://github.com/samvera/active_fedora/issues/393)
- RDF::ReaderError with 7.0.1 [\#387](https://github.com/samvera/active_fedora/issues/387)

**Merged pull requests:**

- Adding data.nil? guard for deserialize [\#398](https://github.com/samvera/active_fedora/pull/398) ([jeremyf](https://github.com/jeremyf))
- Enabled class\_name constantization on access [\#396](https://github.com/samvera/active_fedora/pull/396) ([no-reply](https://github.com/no-reply))
- Adding error for bad nested attribute arguments [\#395](https://github.com/samvera/active_fedora/pull/395) ([no-reply](https://github.com/no-reply))
- Removed duplicate properties hash from AF::Rdf [\#394](https://github.com/samvera/active_fedora/pull/394) ([no-reply](https://github.com/no-reply))
- Making missing AF::Base objects act as Resources [\#392](https://github.com/samvera/active_fedora/pull/392) ([no-reply](https://github.com/no-reply))
- Fix belongs\_to cmodel inheritance. [\#391](https://github.com/samvera/active_fedora/pull/391) ([scande3](https://github.com/scande3))
- fixing assignment of rdf\_subjects in \#attributes= [\#390](https://github.com/samvera/active_fedora/pull/390) ([no-reply](https://github.com/no-reply))
- fixing misused RuntimeError in AF::Rdf::Resource [\#389](https://github.com/samvera/active_fedora/pull/389) ([no-reply](https://github.com/no-reply))
- Passes all content setting through the deserialization method. [\#388](https://github.com/samvera/active_fedora/pull/388) ([tpendragon](https://github.com/tpendragon))
- Allow non-default ds type configurations in named ds specs [\#386](https://github.com/samvera/active_fedora/pull/386) ([barmintor](https://github.com/barmintor))
- Add CollectionProxy\#load\_from\_solr \(delegated to association\)  [\#385](https://github.com/samvera/active_fedora/pull/385) ([dchandekstark](https://github.com/dchandekstark))
- Corrected method call to :loaded! in HasManyAssociation \(fixes \#383\) [\#384](https://github.com/samvera/active_fedora/pull/384) ([dchandekstark](https://github.com/dchandekstark))

## [v7.0.1](https://github.com/samvera/active_fedora/tree/v7.0.1) (2014-04-01)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v7.0.0...v7.0.1)

**Closed issues:**

- HasAndBelongsToManyAssociation does not have `empty?` [\#381](https://github.com/samvera/active_fedora/issues/381)

**Merged pull requests:**

- HasAndBelongsToManyAssociation should have \#empty?. Fixes \#381 [\#382](https://github.com/samvera/active_fedora/pull/382) ([jcoyne](https://github.com/jcoyne))

## [v7.0.0](https://github.com/samvera/active_fedora/tree/v7.0.0) (2014-03-31)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v7.0.0.rc3...v7.0.0)

**Closed issues:**

- index.type :boolean for NtriplesRdfDatastream [\#321](https://github.com/samvera/active_fedora/issues/321)
- RDF should allow for date to include time [\#271](https://github.com/samvera/active_fedora/issues/271)

**Merged pull requests:**

- Adding check to be certain the owner has not already been deleted before... [\#380](https://github.com/samvera/active_fedora/pull/380) ([carolyncole](https://github.com/carolyncole))

## [v7.0.0.rc3](https://github.com/samvera/active_fedora/tree/v7.0.0.rc3) (2014-03-18)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.7.7...v7.0.0.rc3)

**Closed issues:**

- ActiveFedora::Relation isn't caching properly [\#373](https://github.com/samvera/active_fedora/issues/373)
- SpecialThing sample class is broken. [\#368](https://github.com/samvera/active_fedora/issues/368)
- Calling datastream without dsid deprecation warning. [\#367](https://github.com/samvera/active_fedora/issues/367)
- Solr field name deprecation warning appearing by default in samples [\#366](https://github.com/samvera/active_fedora/issues/366)
- Datastream should take a :content option instead of :blob [\#365](https://github.com/samvera/active_fedora/issues/365)
- Rubydora 1.7.2 compatibility with AF 6.7.6 [\#354](https://github.com/samvera/active_fedora/issues/354)
- Rubydora 1.7.2 compatibility with AF 7.0.0 [\#353](https://github.com/samvera/active_fedora/issues/353)
- Unused lines in ActiveFedora::Associations::AssociationCollection\#find\_target break working code [\#234](https://github.com/samvera/active_fedora/issues/234)

**Merged pull requests:**

- Removed deprecated YAMLAdapter [\#379](https://github.com/samvera/active_fedora/pull/379) ([jcoyne](https://github.com/jcoyne))
- Move all the RDF related classes to the rdf directory [\#378](https://github.com/samvera/active_fedora/pull/378) ([jcoyne](https://github.com/jcoyne))
- Overhauling implementatation of ActiveFedora::Rdf [\#377](https://github.com/samvera/active_fedora/pull/377) ([no-reply](https://github.com/no-reply))
- Track when a relation is loaded. Fixes \#373 [\#376](https://github.com/samvera/active_fedora/pull/376) ([jcoyne](https://github.com/jcoyne))
- Test rails 4.1 [\#375](https://github.com/samvera/active_fedora/pull/375) ([jcoyne](https://github.com/jcoyne))
- Wrap string conditions in parentheses in order to preserve boolean logic [\#374](https://github.com/samvera/active_fedora/pull/374) ([cjcolvar](https://github.com/cjcolvar))
- Allow chaining of \#where with combination of string and hash arguments [\#372](https://github.com/samvera/active_fedora/pull/372) ([cjcolvar](https://github.com/cjcolvar))
- stub repository\_profile for sharding unit tests. Fixes \#353 [\#371](https://github.com/samvera/active_fedora/pull/371) ([jcoyne](https://github.com/jcoyne))
- When initializing a datastream, autogenerate a dsid if none is supplied [\#370](https://github.com/samvera/active_fedora/pull/370) ([jcoyne](https://github.com/jcoyne))
- Fix OmDatastream\#from\_solr to work with solr prefixes [\#369](https://github.com/samvera/active_fedora/pull/369) ([jcoyne](https://github.com/jcoyne))
- Minor fixes to specs [\#363](https://github.com/samvera/active_fedora/pull/363) ([mbklein](https://github.com/mbklein))
- Adding the ability to reload before call backs on save. [\#358](https://github.com/samvera/active_fedora/pull/358) ([carolyncole](https://github.com/carolyncole))
- Compare dates as dates \(not strings\). Fixes \#356 [\#357](https://github.com/samvera/active_fedora/pull/357) ([jcoyne](https://github.com/jcoyne))
- Keep solr modification time in sync with fedora modification time.  Issue projecthydra/active\_fedora\#351 [\#355](https://github.com/samvera/active_fedora/pull/355) ([val99erie](https://github.com/val99erie))

## [v6.7.7](https://github.com/samvera/active_fedora/tree/v6.7.7) (2014-02-26)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v7.0.0.rc2...v6.7.7)

**Closed issues:**

- Intermittent failure in spec/integration/auditable\_spec.rb [\#356](https://github.com/samvera/active_fedora/issues/356)
- Solr field 'system\_modified\_dtsi' doesn't get updated when you update a fedora object [\#351](https://github.com/samvera/active_fedora/issues/351)

**Merged pull requests:**

- Backported changes from master to 6-7-stable for rubydora 1.7.1+ compatibility [\#362](https://github.com/samvera/active_fedora/pull/362) ([dchandekstark](https://github.com/dchandekstark))

## [v7.0.0.rc2](https://github.com/samvera/active_fedora/tree/v7.0.0.rc2) (2014-02-10)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.7.6...v7.0.0.rc2)

**Closed issues:**

- Rubydora 1.7.1 breaks active-fedora tests [\#349](https://github.com/samvera/active_fedora/issues/349)
- Deprecate Datastream\#validate\_content\_present [\#347](https://github.com/samvera/active_fedora/issues/347)
- Datastream\#prefix should only be applied to fields defined by that datastream. [\#340](https://github.com/samvera/active_fedora/issues/340)
- 7.0.0.pre3 key error accessing property loaded from solr [\#333](https://github.com/samvera/active_fedora/issues/333)
- ActiveFedora 6.7.4 doesn't work with rubydora 1.7.0 [\#332](https://github.com/samvera/active_fedora/issues/332)

**Merged pull requests:**

- Rubydora 1.7.1 [\#350](https://github.com/samvera/active_fedora/pull/350) ([jcoyne](https://github.com/jcoyne))
- Refactor attribute methods for simplicity and readability [\#348](https://github.com/samvera/active_fedora/pull/348) ([jcoyne](https://github.com/jcoyne))
- remove copycode in DS model helpers [\#345](https://github.com/samvera/active_fedora/pull/345) ([barmintor](https://github.com/barmintor))
- Move \#where and \#order into QueryMethods and test for immutability [\#344](https://github.com/samvera/active_fedora/pull/344) ([cjcolvar](https://github.com/cjcolvar))
- abstract nokogiri-related DS methods into a reusable mixin [\#342](https://github.com/samvera/active_fedora/pull/342) ([barmintor](https://github.com/barmintor))
- Datastream\#prefix should be applied to fields defined by that datastream [\#341](https://github.com/samvera/active_fedora/pull/341) ([jcoyne](https://github.com/jcoyne))
- Default to empty graph if no graph supplied to initializer [\#338](https://github.com/samvera/active_fedora/pull/338) ([cjcolvar](https://github.com/cjcolvar))

## [v6.7.6](https://github.com/samvera/active_fedora/tree/v6.7.6) (2014-01-22)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v7.0.0.rc1...v6.7.6)

**Merged pull requests:**

- Patch ActiveFedora::SolrDigitalObject for Rubydora 1.7.0 compatibility. [\#339](https://github.com/samvera/active_fedora/pull/339) ([dchandekstark](https://github.com/dchandekstark))

## [v7.0.0.rc1](https://github.com/samvera/active_fedora/tree/v7.0.0.rc1) (2014-01-21)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.7.5...v7.0.0.rc1)

**Merged pull requests:**

- relation scopes should not be mutable [\#337](https://github.com/samvera/active_fedora/pull/337) ([jcoyne](https://github.com/jcoyne))
- When an object is loaded from solr, it should be able to access attributes [\#336](https://github.com/samvera/active_fedora/pull/336) ([jcoyne](https://github.com/jcoyne))
- Don't raise a key error if a field can't be found in the solr document [\#335](https://github.com/samvera/active_fedora/pull/335) ([jcoyne](https://github.com/jcoyne))

## [v6.7.5](https://github.com/samvera/active_fedora/tree/v6.7.5) (2014-01-17)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v7.0.0.pre3...v6.7.5)

**Merged pull requests:**

- Support for rubydora 1.7.0 [\#334](https://github.com/samvera/active_fedora/pull/334) ([jcoyne](https://github.com/jcoyne))

## [v7.0.0.pre3](https://github.com/samvera/active_fedora/tree/v7.0.0.pre3) (2014-01-17)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.7.4...v7.0.0.pre3)

**Closed issues:**

- OmDatastream\#to\_solr should prefix fields with datastream name [\#330](https://github.com/samvera/active_fedora/issues/330)
- Can Associations::AssociationProxy be a kind of ActiveFedora::Relation? [\#194](https://github.com/samvera/active_fedora/issues/194)

**Merged pull requests:**

- Create a mechanism to prefix fields in solr for OmDatastream [\#331](https://github.com/samvera/active_fedora/pull/331) ([jcoyne](https://github.com/jcoyne))
- Added SolrService.raw\_query [\#329](https://github.com/samvera/active_fedora/pull/329) ([jcoyne](https://github.com/jcoyne))
- When dissociating deleted records from a has\_many association check the ... [\#328](https://github.com/samvera/active_fedora/pull/328) ([jcoyne](https://github.com/jcoyne))
- Freeze should make the object immutable [\#327](https://github.com/samvera/active_fedora/pull/327) ([jcoyne](https://github.com/jcoyne))
- Consolidated logic paths for creating a solr clause [\#326](https://github.com/samvera/active_fedora/pull/326) ([jcoyne](https://github.com/jcoyne))
- Use rsolr 1.0.10.pre1 [\#325](https://github.com/samvera/active_fedora/pull/325) ([jcoyne](https://github.com/jcoyne))
- Use the escape mechanism in RSolr instead of maintaining our own [\#324](https://github.com/samvera/active_fedora/pull/324) ([jcoyne](https://github.com/jcoyne))
- Use soft commits to speed up AF requests [\#323](https://github.com/samvera/active_fedora/pull/323) ([jcoyne](https://github.com/jcoyne))
- Use \#new\_record? on internal objects to avoid a deprecation warning [\#322](https://github.com/samvera/active_fedora/pull/322) ([jcoyne](https://github.com/jcoyne))

## [v6.7.4](https://github.com/samvera/active_fedora/tree/v6.7.4) (2014-01-15)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v7.0.0.pre2...v6.7.4)

## [v7.0.0.pre2](https://github.com/samvera/active_fedora/tree/v7.0.0.pre2) (2014-01-14)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v7.0.0.pre1...v7.0.0.pre2)

**Merged pull requests:**

- Add SolrDigitalObject\#new\_record?, deprecate \#new? [\#320](https://github.com/samvera/active_fedora/pull/320) ([jcoyne](https://github.com/jcoyne))

## [v7.0.0.pre1](https://github.com/samvera/active_fedora/tree/v7.0.0.pre1) (2014-01-13)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.7.3...v7.0.0.pre1)

**Closed issues:**

- has\_metadata should raise an error if the type argument isn't provided [\#309](https://github.com/samvera/active_fedora/issues/309)
- has\_attributes should raise an exception if the datastream property isn't a string. [\#308](https://github.com/samvera/active_fedora/issues/308)
- Avoid calling respond\_to? [\#295](https://github.com/samvera/active_fedora/issues/295)

**Merged pull requests:**

- The object should be indexed before triggering the after\_save [\#319](https://github.com/samvera/active_fedora/pull/319) ([jcoyne](https://github.com/jcoyne))
- Rubydora 1.7 [\#318](https://github.com/samvera/active_fedora/pull/318) ([jcoyne](https://github.com/jcoyne))
- A nicer inspect. Show associations, no trailing commas [\#317](https://github.com/samvera/active_fedora/pull/317) ([jcoyne](https://github.com/jcoyne))
- Don't automatically load the associated object when setting the parent\_id [\#316](https://github.com/samvera/active_fedora/pull/316) ([jcoyne](https://github.com/jcoyne))
- Add UnsavedDigitalObject\#new\_record? [\#315](https://github.com/samvera/active_fedora/pull/315) ([jcoyne](https://github.com/jcoyne))
- Reset the relationship when an id setter is called [\#314](https://github.com/samvera/active_fedora/pull/314) ([jcoyne](https://github.com/jcoyne))
- Accept a symbol as the datastream property for has\_attributes. Fixes \#308 [\#313](https://github.com/samvera/active_fedora/pull/313) ([jcoyne](https://github.com/jcoyne))
- Ensure that dsid and type are provided to has\_metadata. Fixes \#309 [\#312](https://github.com/samvera/active_fedora/pull/312) ([jcoyne](https://github.com/jcoyne))
- Added \#find\(\) on a collection relation [\#311](https://github.com/samvera/active_fedora/pull/311) ([jcoyne](https://github.com/jcoyne))
- Fix ActiveFedora under Ruby 2.1. [\#310](https://github.com/samvera/active_fedora/pull/310) ([jcoyne](https://github.com/jcoyne))
- Move query methods onto the relation instead of the class. [\#307](https://github.com/samvera/active_fedora/pull/307) ([jcoyne](https://github.com/jcoyne))
- Add destroy\_all on a collection association [\#306](https://github.com/samvera/active_fedora/pull/306) ([jcoyne](https://github.com/jcoyne))
- Use explicit delegations [\#305](https://github.com/samvera/active_fedora/pull/305) ([jcoyne](https://github.com/jcoyne))
- Remove unused delegates. Simplify method\_missing logic [\#304](https://github.com/samvera/active_fedora/pull/304) ([jcoyne](https://github.com/jcoyne))
- Added \#select to Relation [\#303](https://github.com/samvera/active_fedora/pull/303) ([jcoyne](https://github.com/jcoyne))
- add scoping. Remove metaprogramming. [\#302](https://github.com/samvera/active_fedora/pull/302) ([jcoyne](https://github.com/jcoyne))
- CollectionProxy\#new doesn't need method\_missing [\#301](https://github.com/samvera/active_fedora/pull/301) ([jcoyne](https://github.com/jcoyne))
- Add hash options to CollectionAssociation\#load\_from\_solr [\#300](https://github.com/samvera/active_fedora/pull/300) ([dchandekstark](https://github.com/dchandekstark))
- Removed calls to Array.wrap [\#299](https://github.com/samvera/active_fedora/pull/299) ([jcoyne](https://github.com/jcoyne))
- ActiveFedora::SolrService.reify\_solr\_result modified to pass Solr hit to... [\#298](https://github.com/samvera/active_fedora/pull/298) ([dchandekstark](https://github.com/dchandekstark))
- Cache registered attributes [\#297](https://github.com/samvera/active_fedora/pull/297) ([jcoyne](https://github.com/jcoyne))
- Added Base\#to\_json and Base\#attributes. [\#296](https://github.com/samvera/active_fedora/pull/296) ([jcoyne](https://github.com/jcoyne))
- RDF datastreams should properly de/serialize integers [\#294](https://github.com/samvera/active_fedora/pull/294) ([jcoyne](https://github.com/jcoyne))
- Add a way to get the primary solr name for a field [\#293](https://github.com/samvera/active_fedora/pull/293) ([jcoyne](https://github.com/jcoyne))
- Renamed testing gemfiles [\#292](https://github.com/samvera/active_fedora/pull/292) ([jcoyne](https://github.com/jcoyne))
- Updating generator to not have generate method [\#290](https://github.com/samvera/active_fedora/pull/290) ([jeremyf](https://github.com/jeremyf))
- Adding \#reflect\_on\_all\_autosave\_associations [\#289](https://github.com/samvera/active_fedora/pull/289) ([jeremyf](https://github.com/jeremyf))
- Force RDF data to be UTF-8 [\#286](https://github.com/samvera/active_fedora/pull/286) ([jcoyne](https://github.com/jcoyne))
- Freeze deleted objects [\#284](https://github.com/samvera/active_fedora/pull/284) ([jcoyne](https://github.com/jcoyne))
- Calling delete on an unsaved object should not raise an exception [\#283](https://github.com/samvera/active_fedora/pull/283) ([jcoyne](https://github.com/jcoyne))
- Upgrade to rdf-rdfxml 1.1.0 [\#282](https://github.com/samvera/active_fedora/pull/282) ([jcoyne](https://github.com/jcoyne))
- Simplify RdfDatastream\#prefix [\#281](https://github.com/samvera/active_fedora/pull/281) ([jcoyne](https://github.com/jcoyne))
- Give a clue as to the class when trying to assign to an invalid attribute [\#280](https://github.com/samvera/active_fedora/pull/280) ([jcoyne](https://github.com/jcoyne))
- Removed dead code from SemanticNode [\#279](https://github.com/samvera/active_fedora/pull/279) ([jcoyne](https://github.com/jcoyne))
- Organize the methods in Base into their own modules. [\#278](https://github.com/samvera/active_fedora/pull/278) ([jcoyne](https://github.com/jcoyne))
- Deprecate Base.pids\_from\_uris [\#277](https://github.com/samvera/active_fedora/pull/277) ([jcoyne](https://github.com/jcoyne))
- Base doesn't need to extend Model [\#276](https://github.com/samvera/active_fedora/pull/276) ([jcoyne](https://github.com/jcoyne))
- Changes behavior of ActiveFedora::Base\#find to treat empty arrays the sa... [\#273](https://github.com/samvera/active_fedora/pull/273) ([afred](https://github.com/afred))
- Extracting .best\_model\_for from AF::Base [\#270](https://github.com/samvera/active_fedora/pull/270) ([jeremyf](https://github.com/jeremyf))
- Remove all textile and RedCloth dependencies [\#269](https://github.com/samvera/active_fedora/pull/269) ([jcoyne](https://github.com/jcoyne))
- attribute accessors shouldn't accept an unknown dsid [\#268](https://github.com/samvera/active_fedora/pull/268) ([jcoyne](https://github.com/jcoyne))
- has\_attributes should raise an exception if the datastream property [\#267](https://github.com/samvera/active_fedora/pull/267) ([jcoyne](https://github.com/jcoyne))
- Removed spec that was a duplicate of spec/unit/base\_delegate\_spec.rb [\#264](https://github.com/samvera/active_fedora/pull/264) ([jcoyne](https://github.com/jcoyne))
- Rename base\_delegate\_spec to attributes\_spec [\#263](https://github.com/samvera/active_fedora/pull/263) ([jcoyne](https://github.com/jcoyne))
- Removed spec that was duplicate of spec/integration/attributes\_spec.rb [\#262](https://github.com/samvera/active_fedora/pull/262) ([jcoyne](https://github.com/jcoyne))
- Removed an incorrect usage of has\_attributes. This applied only to delegate [\#261](https://github.com/samvera/active_fedora/pull/261) ([jcoyne](https://github.com/jcoyne))
- Adding more verbose logging to specs [\#260](https://github.com/samvera/active_fedora/pull/260) ([jeremyf](https://github.com/jeremyf))

## [v6.7.3](https://github.com/samvera/active_fedora/tree/v6.7.3) (2013-12-19)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.7.2...v6.7.3)

## [v6.7.2](https://github.com/samvera/active_fedora/tree/v6.7.2) (2013-12-18)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.7.1...v6.7.2)

**Closed issues:**

- Method missing for ActiveFedora::AutosaveAssociation\#reflect\_on\_all\_autosave\_associations [\#254](https://github.com/samvera/active_fedora/issues/254)

## [v6.7.1](https://github.com/samvera/active_fedora/tree/v6.7.1) (2013-12-18)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.7.0...v6.7.1)

**Closed issues:**

- GettingNoMethodError: undefined method `repository' for nil:NilClass while adding OMDatastream [\#275](https://github.com/samvera/active_fedora/issues/275)
- Calling \#find with an empty array causes Rsolr to raise a HTTP 400 error. [\#272](https://github.com/samvera/active_fedora/issues/272)
- attribute readers should raise an exception if the supplied dsid isn't a known datastream [\#266](https://github.com/samvera/active_fedora/issues/266)
- has\_attributes should raise an exception if the datastream property isn't specified. [\#265](https://github.com/samvera/active_fedora/issues/265)
- Should be able to use delegate with `to` parameter for multiple fields [\#255](https://github.com/samvera/active_fedora/issues/255)
- rdf-rdfxml version 1.0.2 breaks ActiveFedora specs [\#157](https://github.com/samvera/active_fedora/issues/157)

**Merged pull requests:**

- Renaming invoke -\> generate [\#288](https://github.com/samvera/active_fedora/pull/288) ([jeremyf](https://github.com/jeremyf))
- Force RDF data to be UTF-8 [\#287](https://github.com/samvera/active_fedora/pull/287) ([jcoyne](https://github.com/jcoyne))

## [v6.7.0](https://github.com/samvera/active_fedora/tree/v6.7.0) (2013-10-29)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.7.0.rc1...v6.7.0)

**Merged pull requests:**

- Remove loading of rake tasks because they are already loaded in the railtie [\#259](https://github.com/samvera/active_fedora/pull/259) ([cjcolvar](https://github.com/cjcolvar))

## [v6.7.0.rc1](https://github.com/samvera/active_fedora/tree/v6.7.0.rc1) (2013-10-25)

[Full Changelog](https://github.com/samvera/active_fedora/compare/list...v6.7.0.rc1)

**Merged pull requests:**

- Added has\_attributes to replace delegate\_to [\#257](https://github.com/samvera/active_fedora/pull/257) ([jcoyne](https://github.com/jcoyne))

## [list](https://github.com/samvera/active_fedora/tree/list) (2013-10-24)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.6.1...list)

**Merged pull requests:**

- Use hydra-jetty from master [\#258](https://github.com/samvera/active_fedora/pull/258) ([jcoyne](https://github.com/jcoyne))
- Alter test so that it's compatible with solr document produced by om 3.0.4 [\#253](https://github.com/samvera/active_fedora/pull/253) ([jcoyne](https://github.com/jcoyne))
- Remove vestigial test app [\#252](https://github.com/samvera/active_fedora/pull/252) ([jcoyne](https://github.com/jcoyne))
- Corrected Google group \(Fixes \#235\). [\#238](https://github.com/samvera/active_fedora/pull/238) ([dchandekstark](https://github.com/dchandekstark))
- Adding a loop for getting more than solr\_page\_size \(default 200\) results... [\#228](https://github.com/samvera/active_fedora/pull/228) ([carolyncole](https://github.com/carolyncole))
- Switch find's cast to default as true [\#225](https://github.com/samvera/active_fedora/pull/225) ([jeremyf](https://github.com/jeremyf))
- You should be able to access the id property like a stored property [\#222](https://github.com/samvera/active_fedora/pull/222) ([jcoyne](https://github.com/jcoyne))
- Id properties should just write to RELS-EXT without causing a load [\#221](https://github.com/samvera/active_fedora/pull/221) ([jcoyne](https://github.com/jcoyne))
- Replace method\_missing datastream accessors with generated accessors [\#220](https://github.com/samvera/active_fedora/pull/220) ([jcoyne](https://github.com/jcoyne))
- Don't use inline datastreams for rdfxml [\#219](https://github.com/samvera/active_fedora/pull/219) ([jcoyne](https://github.com/jcoyne))
- Autosave associations ported from Rails [\#217](https://github.com/samvera/active_fedora/pull/217) ([jcoyne](https://github.com/jcoyne))
- bump to use hydra-jetty 5.2.0 [\#216](https://github.com/samvera/active_fedora/pull/216) ([cbeer](https://github.com/cbeer))
- Fix inference for predicates on has\_many relationships [\#215](https://github.com/samvera/active_fedora/pull/215) ([jcoyne](https://github.com/jcoyne))
- Callbacks for add and remove on a has\_and\_belongs\_to\_many association [\#214](https://github.com/samvera/active_fedora/pull/214) ([jcoyne](https://github.com/jcoyne))
- Don't attempt to remove associated objects that are already deleted.  [\#213](https://github.com/samvera/active_fedora/pull/213) ([jcoyne](https://github.com/jcoyne))
- Added destroy on has\_and\_belongs\_to\_many [\#212](https://github.com/samvera/active_fedora/pull/212) ([jcoyne](https://github.com/jcoyne))
- Split has\_and\_belongs\_to\_many specs into their own file [\#211](https://github.com/samvera/active_fedora/pull/211) ([jcoyne](https://github.com/jcoyne))
- Association methods are now generated in modules [\#210](https://github.com/samvera/active_fedora/pull/210) ([jcoyne](https://github.com/jcoyne))
- Use proper objects to do the work of building associations. [\#209](https://github.com/samvera/active_fedora/pull/209) ([jcoyne](https://github.com/jcoyne))
- Split AssociationProxy into Association class \(and subclasses\) [\#208](https://github.com/samvera/active_fedora/pull/208) ([jcoyne](https://github.com/jcoyne))
- Removed deprecated options to find \(:all, :first, :last\) [\#206](https://github.com/samvera/active_fedora/pull/206) ([jcoyne](https://github.com/jcoyne))
- Removed deprecated class NokogiriDatastream [\#205](https://github.com/samvera/active_fedora/pull/205) ([jcoyne](https://github.com/jcoyne))
- Removed the deprecated unique attribute on delegates [\#204](https://github.com/samvera/active_fedora/pull/204) ([jcoyne](https://github.com/jcoyne))
- Remove deprecated methods including: [\#203](https://github.com/samvera/active_fedora/pull/203) ([jcoyne](https://github.com/jcoyne))

## [v6.6.1](https://github.com/samvera/active_fedora/tree/v6.6.1) (2013-10-23)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.6.0...v6.6.1)

**Closed issues:**

- active\_fedora depends on mime-types \>= 1.16 [\#251](https://github.com/samvera/active_fedora/issues/251)
- ActiveFedora::Base.find should cast by default [\#223](https://github.com/samvera/active_fedora/issues/223)

**Merged pull requests:**

- Don't try to track changes on delegates that are not attributes [\#256](https://github.com/samvera/active_fedora/pull/256) ([jcoyne](https://github.com/jcoyne))

## [v6.6.0](https://github.com/samvera/active_fedora/tree/v6.6.0) (2013-10-09)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v5.7.1...v6.6.0)

**Merged pull requests:**

- Add \_destroy method for building nested forms [\#248](https://github.com/samvera/active_fedora/pull/248) ([jcoyne](https://github.com/jcoyne))
- Removed the pid placeholder `\_\_DO\_NOT\_USE\_\_` [\#247](https://github.com/samvera/active_fedora/pull/247) ([jcoyne](https://github.com/jcoyne))
- Allow relationships to accept instances of RDF::URI as their predicates [\#246](https://github.com/samvera/active_fedora/pull/246) ([jcoyne](https://github.com/jcoyne))
- Remove internal deprecation [\#243](https://github.com/samvera/active_fedora/pull/243) ([jcoyne](https://github.com/jcoyne))

## [v5.7.1](https://github.com/samvera/active_fedora/tree/v5.7.1) (2013-10-08)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v5.7.0...v5.7.1)

**Merged pull requests:**

- Set content from the ngxml document, and update the stored datastream\_co... [\#245](https://github.com/samvera/active_fedora/pull/245) ([cbeer](https://github.com/cbeer))

## [v5.7.0](https://github.com/samvera/active_fedora/tree/v5.7.0) (2013-10-07)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.6.0.rc5...v5.7.0)

**Merged pull requests:**

- Backport Nokogiri fixes into AF5 [\#244](https://github.com/samvera/active_fedora/pull/244) ([cbeer](https://github.com/cbeer))

## [v6.6.0.rc5](https://github.com/samvera/active_fedora/tree/v6.6.0.rc5) (2013-10-04)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.6.0.rc4...v6.6.0.rc5)

**Closed issues:**

- README points to wrong Google group for getting help [\#235](https://github.com/samvera/active_fedora/issues/235)

**Merged pull requests:**

- Error in find all [\#241](https://github.com/samvera/active_fedora/pull/241) ([jcoyne](https://github.com/jcoyne))
- Revert "Removed unused code that breaks certain use cases \(Fixes \#234\)." [\#240](https://github.com/samvera/active_fedora/pull/240) ([jeremyf](https://github.com/jeremyf))
- Fix pr236 [\#239](https://github.com/samvera/active_fedora/pull/239) ([dchandekstark](https://github.com/dchandekstark))
- Fix deprecation warning on has\_many when class\_name =\> 'ActiveFedora::Base' [\#237](https://github.com/samvera/active_fedora/pull/237) ([jcoyne](https://github.com/jcoyne))
- Removed unused code that breaks certain use cases [\#236](https://github.com/samvera/active_fedora/pull/236) ([dchandekstark](https://github.com/dchandekstark))

## [v6.6.0.rc4](https://github.com/samvera/active_fedora/tree/v6.6.0.rc4) (2013-10-04)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.6.0.rc3...v6.6.0.rc4)

**Merged pull requests:**

- Reify solr casting [\#232](https://github.com/samvera/active_fedora/pull/232) ([jcoyne](https://github.com/jcoyne))

## [v6.6.0.rc3](https://github.com/samvera/active_fedora/tree/v6.6.0.rc3) (2013-10-03)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.6.0.rc2...v6.6.0.rc3)

**Merged pull requests:**

- Destroy can fail [\#231](https://github.com/samvera/active_fedora/pull/231) ([jcoyne](https://github.com/jcoyne))
- Avoid deprecation [\#230](https://github.com/samvera/active_fedora/pull/230) ([jcoyne](https://github.com/jcoyne))

## [v6.6.0.rc2](https://github.com/samvera/active_fedora/tree/v6.6.0.rc2) (2013-10-02)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.6.0.rc1...v6.6.0.rc2)

**Merged pull requests:**

- Cast relationships [\#229](https://github.com/samvera/active_fedora/pull/229) ([jcoyne](https://github.com/jcoyne))

## [v6.6.0.rc1](https://github.com/samvera/active_fedora/tree/v6.6.0.rc1) (2013-09-30)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.6.0.pre4...v6.6.0.rc1)

## [v6.6.0.pre4](https://github.com/samvera/active_fedora/tree/v6.6.0.pre4) (2013-09-28)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.6.0.pre3...v6.6.0.pre4)

## [v6.6.0.pre3](https://github.com/samvera/active_fedora/tree/v6.6.0.pre3) (2013-09-27)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.6.0.pre2...v6.6.0.pre3)

## [v6.6.0.pre2](https://github.com/samvera/active_fedora/tree/v6.6.0.pre2) (2013-09-27)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.6.0.pre1...v6.6.0.pre2)

**Merged pull requests:**

- Only deprecate cast on base [\#227](https://github.com/samvera/active_fedora/pull/227) ([jcoyne](https://github.com/jcoyne))

## [v6.6.0.pre1](https://github.com/samvera/active_fedora/tree/v6.6.0.pre1) (2013-09-27)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.5.1...v6.6.0.pre1)

**Implemented enhancements:**

- Mass assignment, Computed properties and Complex properties in RDF [\#75](https://github.com/samvera/active_fedora/issues/75)

**Fixed bugs:**

- Rails 4 scaffold generator changed the methods it used [\#144](https://github.com/samvera/active_fedora/issues/144)

**Closed issues:**

- Infinite Loop in ActiveFedora::Associations::AssociationCollection.load\_target [\#199](https://github.com/samvera/active_fedora/issues/199)
- find\(:all\) and find\(:first\) ignore :cast=\>true [\#193](https://github.com/samvera/active_fedora/issues/193)
- delegate should default to single value \(in 7.x\) [\#147](https://github.com/samvera/active_fedora/issues/147)
- Problem deleting an object with a has\_many relationship when the dependent object is deleted [\#36](https://github.com/samvera/active_fedora/issues/36)

**Merged pull requests:**

- Deprecate .find's cast default option [\#226](https://github.com/samvera/active_fedora/pull/226) ([jeremyf](https://github.com/jeremyf))
- Remove outdated fixture loading line from README.  [\#218](https://github.com/samvera/active_fedora/pull/218) ([scande3](https://github.com/scande3))
- Support for extended cmodels \(read-only\) [\#207](https://github.com/samvera/active_fedora/pull/207) ([scande3](https://github.com/scande3))
- delegate and delegate\_to should use 'multiple' rather than 'unique'.  [\#202](https://github.com/samvera/active_fedora/pull/202) ([jcoyne](https://github.com/jcoyne))
- Deprecated find\(:all\), find\(:first\), find\(:last\) [\#201](https://github.com/samvera/active_fedora/pull/201) ([jcoyne](https://github.com/jcoyne))
- Prevent infinite loop when Fedora and Solr are out of sync \(fixes \#199\) [\#200](https://github.com/samvera/active_fedora/pull/200) ([mbklein](https://github.com/mbklein))

## [v6.5.1](https://github.com/samvera/active_fedora/tree/v6.5.1) (2013-09-10)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.5.0...v6.5.1)

**Merged pull requests:**

- ActiveFedora::Predicates.set\_predicates allows you to set predicates without wiping out existing configs [\#197](https://github.com/samvera/active_fedora/pull/197) ([flyingzumwalt](https://github.com/flyingzumwalt))

## [v6.5.0](https://github.com/samvera/active_fedora/tree/v6.5.0) (2013-08-28)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.4.5...v6.5.0)

**Closed issues:**

- ActiveFedora::Relation\#last method not implemented [\#184](https://github.com/samvera/active_fedora/issues/184)
- Update integration tests to build objects programmatically, not use serialized FOXML. [\#96](https://github.com/samvera/active_fedora/issues/96)
- ActiveFedora::Base.reindex\_everything indexes fedora reserved objects [\#70](https://github.com/samvera/active_fedora/issues/70)

**Merged pull requests:**

- Delegate relation methods to the array [\#196](https://github.com/samvera/active_fedora/pull/196) ([jcoyne](https://github.com/jcoyne))
- Use an error message that gives a thourough explanation and a suggestion... [\#195](https://github.com/samvera/active_fedora/pull/195) ([jcoyne](https://github.com/jcoyne))
- An empty query value that is a string should not return all documents. [\#192](https://github.com/samvera/active_fedora/pull/192) ([atomical](https://github.com/atomical))
- Include ActiveModel::Dirty on Base, call field\_will\_change! on delegated methods, and track changes on save [\#191](https://github.com/samvera/active_fedora/pull/191) ([cjcolvar](https://github.com/cjcolvar))
- Rdf terminologies should be inheritable [\#189](https://github.com/samvera/active_fedora/pull/189) ([jcoyne](https://github.com/jcoyne))
- Error when assigning an attribute that hasn't been delegated [\#188](https://github.com/samvera/active_fedora/pull/188) ([jcoyne](https://github.com/jcoyne))
- Added RdfNode::TermProxy.first\_or\_create [\#187](https://github.com/samvera/active_fedora/pull/187) ([jcoyne](https://github.com/jcoyne))
- replace method\_missing technique in rdf\_node with an accessor generator [\#186](https://github.com/samvera/active_fedora/pull/186) ([jcoyne](https://github.com/jcoyne))
- Add ActiveFedora::Relation\#last.  Resolves \#184 [\#185](https://github.com/samvera/active_fedora/pull/185) ([acurley](https://github.com/acurley))
- RdfNode::TermProxy.build should use the correct class [\#183](https://github.com/samvera/active_fedora/pull/183) ([jcoyne](https://github.com/jcoyne))

## [v6.4.5](https://github.com/samvera/active_fedora/tree/v6.4.5) (2013-08-05)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.4.4...v6.4.5)

**Merged pull requests:**

- Clear rdf lists and proxies [\#182](https://github.com/samvera/active_fedora/pull/182) ([jcoyne](https://github.com/jcoyne))
- When defining rdf terms you should be able to say 'multivalue: false' [\#181](https://github.com/samvera/active_fedora/pull/181) ([jcoyne](https://github.com/jcoyne))
- Created RdfList\#to\_ary and a mechanism for building list nodes. [\#180](https://github.com/samvera/active_fedora/pull/180) ([jcoyne](https://github.com/jcoyne))
- Define UNASSIGNABLE\_KEYS for RdfList.assign\_nested\_attributes... [\#179](https://github.com/samvera/active_fedora/pull/179) ([jcoyne](https://github.com/jcoyne))
- Added RdfList.each [\#178](https://github.com/samvera/active_fedora/pull/178) ([jcoyne](https://github.com/jcoyne))
- Cache the tail node in an RDFList [\#177](https://github.com/samvera/active_fedora/pull/177) ([jcoyne](https://github.com/jcoyne))
- class\_from\_string should have an exit condition when class can't be found [\#176](https://github.com/samvera/active_fedora/pull/176) ([jcoyne](https://github.com/jcoyne))
- Add a warning when you have already registered this RDF.type [\#175](https://github.com/samvera/active_fedora/pull/175) ([jcoyne](https://github.com/jcoyne))
- Rdf lists should only have one RDF.rest node [\#174](https://github.com/samvera/active_fedora/pull/174) ([jcoyne](https://github.com/jcoyne))
- RDF lists should be able to accept nested attributes as a hash [\#173](https://github.com/samvera/active_fedora/pull/173) ([jcoyne](https://github.com/jcoyne))
- Clean up YARD doc warnings [\#172](https://github.com/samvera/active_fedora/pull/172) ([jcoyne](https://github.com/jcoyne))
- An rdf node should be able to set rdf:about [\#171](https://github.com/samvera/active_fedora/pull/171) ([jcoyne](https://github.com/jcoyne))
- Remove RdfObject\#get\_values, it's inherited [\#170](https://github.com/samvera/active_fedora/pull/170) ([jcoyne](https://github.com/jcoyne))

## [v6.4.4](https://github.com/samvera/active_fedora/tree/v6.4.4) (2013-07-30)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.4.3...v6.4.4)

**Closed issues:**

- ActiveFedora::Base.reindex\_everything is too eager to update\_everything. [\#160](https://github.com/samvera/active_fedora/issues/160)

**Merged pull requests:**

- Use get\_config\_path to get the path for the predicate\_mappings.yml [\#168](https://github.com/samvera/active_fedora/pull/168) ([jcoyne](https://github.com/jcoyne))
- has\_and\_belongs\_to\_many can have more than 10 results. [\#167](https://github.com/samvera/active_fedora/pull/167) ([jcoyne](https://github.com/jcoyne))
- Don't reindex fedora-system objects in reindex\_everything [\#163](https://github.com/samvera/active_fedora/pull/163) ([jcoyne](https://github.com/jcoyne))
- Adding "An ActiveModel" shared behavior [\#162](https://github.com/samvera/active_fedora/pull/162) ([jeremyf](https://github.com/jeremyf))
- Allow query parameter AF.reindex\_everything [\#161](https://github.com/samvera/active_fedora/pull/161) ([jeremyf](https://github.com/jeremyf))
- The example test should look for Base.exists?\(\) [\#159](https://github.com/samvera/active_fedora/pull/159) ([jcoyne](https://github.com/jcoyne))
- Filters belongs\_to associations by :class\_name [\#106](https://github.com/samvera/active_fedora/pull/106) ([simonlamb](https://github.com/simonlamb))

## [v6.4.3](https://github.com/samvera/active_fedora/tree/v6.4.3) (2013-07-16)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.4.2...v6.4.3)

**Closed issues:**

- License missing from gemspec [\#154](https://github.com/samvera/active_fedora/issues/154)

**Merged pull requests:**

- class\_from\_string should find sibiling classes [\#158](https://github.com/samvera/active_fedora/pull/158) ([jcoyne](https://github.com/jcoyne))
- Ensuring that AF::Base.find\(""\) raises exception [\#156](https://github.com/samvera/active_fedora/pull/156) ([jeremyf](https://github.com/jeremyf))
- Add lazy reification method to ActiveFedora::SolrService [\#155](https://github.com/samvera/active_fedora/pull/155) ([dchandekstark](https://github.com/dchandekstark))
- Adding mailmap for improving changelog generation [\#153](https://github.com/samvera/active_fedora/pull/153) ([jeremyf](https://github.com/jeremyf))
- Updating active\_support 4's gem dependency [\#152](https://github.com/samvera/active_fedora/pull/152) ([jeremyf](https://github.com/jeremyf))
- Tidying up hash key access of AF::Model [\#151](https://github.com/samvera/active_fedora/pull/151) ([jeremyf](https://github.com/jeremyf))
- Tidying up how ActiveFedora::Base.exists? behaves [\#150](https://github.com/samvera/active_fedora/pull/150) ([jeremyf](https://github.com/jeremyf))
- Remove foxml [\#149](https://github.com/samvera/active_fedora/pull/149) ([jcoyne](https://github.com/jcoyne))
- mock\(\) and stub\(\) are deprecated. Switched to double\(\) [\#148](https://github.com/samvera/active_fedora/pull/148) ([jcoyne](https://github.com/jcoyne))
- Remove all serialized foxml in favor of programmatic creation of fixtures in preparation for Fedora 4 [\#102](https://github.com/samvera/active_fedora/pull/102) ([cjcolvar](https://github.com/cjcolvar))

## [v6.4.2](https://github.com/samvera/active_fedora/tree/v6.4.2) (2013-07-10)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.4.1...v6.4.2)

**Merged pull requests:**

- In activerecord 4.0 the update\(\) method accepts arguments. [\#146](https://github.com/samvera/active_fedora/pull/146) ([jcoyne](https://github.com/jcoyne))

## [v6.4.1](https://github.com/samvera/active_fedora/tree/v6.4.1) (2013-07-10)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.4.0...v6.4.1)

**Closed issues:**

- Infer property on has\_many [\#142](https://github.com/samvera/active_fedora/issues/142)

**Merged pull requests:**

- Infer the property on has\_many. Fixes \#142 [\#145](https://github.com/samvera/active_fedora/pull/145) ([jcoyne](https://github.com/jcoyne))
- Added new\_record? method to Rdf nodes [\#140](https://github.com/samvera/active_fedora/pull/140) ([jcoyne](https://github.com/jcoyne))
- Test the behavior when the node can't be found [\#139](https://github.com/samvera/active_fedora/pull/139) ([jcoyne](https://github.com/jcoyne))
- Rdf nested attributes should accept hashes [\#138](https://github.com/samvera/active_fedora/pull/138) ([jcoyne](https://github.com/jcoyne))
- Added :type to ActiveFedora::QualifiedDublinCoreDatastream::DCTERMS. [\#137](https://github.com/samvera/active_fedora/pull/137) ([dchandekstark](https://github.com/dchandekstark))
- Removed outdated comment that OmDatastream is just an alias for Nokogiri... [\#136](https://github.com/samvera/active_fedora/pull/136) ([dchandekstark](https://github.com/dchandekstark))
- Added :path option to ActiveFedora::QualifiedDublinCoreDatastream\#field ... [\#135](https://github.com/samvera/active_fedora/pull/135) ([dchandekstark](https://github.com/dchandekstark))
- Generate datastream [\#134](https://github.com/samvera/active_fedora/pull/134) ([jcoyne](https://github.com/jcoyne))
- Autoload classes in app/models/datastreams [\#133](https://github.com/samvera/active_fedora/pull/133) ([jcoyne](https://github.com/jcoyne))
- Change generator template to not use named argument 'name' [\#132](https://github.com/samvera/active_fedora/pull/132) ([jcoyne](https://github.com/jcoyne))
- Remove unnecessary require of 'active\_fedora/base' in model template [\#131](https://github.com/samvera/active_fedora/pull/131) ([jcoyne](https://github.com/jcoyne))

## [v6.4.0](https://github.com/samvera/active_fedora/tree/v6.4.0) (2013-07-01)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.4.0.rc4...v6.4.0)

**Closed issues:**

- ActiveFedora::DatastreamCollections should no longer be "experimental" [\#129](https://github.com/samvera/active_fedora/issues/129)

**Merged pull requests:**

- Removing experimental designation, tidying-up the code [\#130](https://github.com/samvera/active_fedora/pull/130) ([awead](https://github.com/awead))
- Providing a YAMLAdaptor for Psych dependency [\#128](https://github.com/samvera/active_fedora/pull/128) ([jeremyf](https://github.com/jeremyf))

## [v6.4.0.rc4](https://github.com/samvera/active_fedora/tree/v6.4.0.rc4) (2013-06-26)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.4.0.rc3...v6.4.0.rc4)

**Fixed bugs:**

- ActiveFedora::Delegating issues with keys being string or symbol [\#123](https://github.com/samvera/active_fedora/issues/123)

**Merged pull requests:**

- better error message when TermProxy encounters bad metadata in the graph [\#127](https://github.com/samvera/active_fedora/pull/127) ([flyingzumwalt](https://github.com/flyingzumwalt))
- Fixing delegate registry lookup [\#126](https://github.com/samvera/active_fedora/pull/126) ([jeremyf](https://github.com/jeremyf))
- Removed duplicate fields from ActiveFedora::QualifiedDublinCoreDatastream::DCTERMS [\#125](https://github.com/samvera/active_fedora/pull/125) ([dchandekstark](https://github.com/dchandekstark))
- Delegate array methods should accept string keys. Fixes \#123 [\#124](https://github.com/samvera/active_fedora/pull/124) ([jcoyne](https://github.com/jcoyne))
- Rdf nested lists [\#122](https://github.com/samvera/active_fedora/pull/122) ([flyingzumwalt](https://github.com/flyingzumwalt))

## [v6.4.0.rc3](https://github.com/samvera/active_fedora/tree/v6.4.0.rc3) (2013-06-24)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.4.0.rc2...v6.4.0.rc3)

**Merged pull requests:**

- Added RdfNode.fields\(\) which returns a list of the fields [\#121](https://github.com/samvera/active_fedora/pull/121) ([jcoyne](https://github.com/jcoyne))

## [v6.4.0.rc2](https://github.com/samvera/active_fedora/tree/v6.4.0.rc2) (2013-06-24)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.4.0.rc1...v6.4.0.rc2)

**Merged pull requests:**

- We should be able to delete rdf nested attributes. [\#119](https://github.com/samvera/active_fedora/pull/119) ([jcoyne](https://github.com/jcoyne))
- Om 3 [\#118](https://github.com/samvera/active_fedora/pull/118) ([jcoyne](https://github.com/jcoyne))

## [v6.4.0.rc1](https://github.com/samvera/active_fedora/tree/v6.4.0.rc1) (2013-06-21)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.3.0...v6.4.0.rc1)

**Closed issues:**

- Create active\_fedora:model generator [\#91](https://github.com/samvera/active_fedora/issues/91)

**Merged pull requests:**

- Deprecated AF::Base\#update\_indexed\_attributes [\#117](https://github.com/samvera/active_fedora/pull/117) ([jcoyne](https://github.com/jcoyne))
- Updating "active\_fedora:model" rails generator [\#116](https://github.com/samvera/active_fedora/pull/116) ([jeremyf](https://github.com/jeremyf))
- Delegate all the array methods for RdfNode::TermProxy [\#115](https://github.com/samvera/active_fedora/pull/115) ([jcoyne](https://github.com/jcoyne))
- Added accepts\_nested\_attributes\_for on RDFNodes [\#114](https://github.com/samvera/active_fedora/pull/114) ([jcoyne](https://github.com/jcoyne))

## [v6.3.0](https://github.com/samvera/active_fedora/tree/v6.3.0) (2013-06-14)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.2.0...v6.3.0)

**Closed issues:**

- Fix typo in test notice: [\#97](https://github.com/samvera/active_fedora/issues/97)
- Update test to be order-agnostic [\#89](https://github.com/samvera/active_fedora/issues/89)
- Use  \_query\_ and !raw to do solr query escaping [\#87](https://github.com/samvera/active_fedora/issues/87)
- Modify or remove tests that check for DC datastreams [\#85](https://github.com/samvera/active_fedora/issues/85)
- Remove use of narm: and hydrangea: namespaces in AF tests [\#84](https://github.com/samvera/active_fedora/issues/84)
- Use Rubydora's \#mint to mint new PIDs [\#83](https://github.com/samvera/active_fedora/issues/83)

**Merged pull requests:**

- Added method: ActiveFedora::Base\#required? [\#111](https://github.com/samvera/active_fedora/pull/111) ([jcoyne](https://github.com/jcoyne))
- Removed redundant MacroReflection\#klass method definition. [\#110](https://github.com/samvera/active_fedora/pull/110) ([dchandekstark](https://github.com/dchandekstark))
- Updated doc comment for .count to reflect change made in commit 1cd412a8... [\#109](https://github.com/samvera/active_fedora/pull/109) ([dchandekstark](https://github.com/dchandekstark))
- Refactor test to use a model that makes sense conceptually \[log skip\] [\#108](https://github.com/samvera/active_fedora/pull/108) ([jcoyne](https://github.com/jcoyne))
- Adding CONTRIBUTORS and mailmap [\#107](https://github.com/samvera/active_fedora/pull/107) ([jeremyf](https://github.com/jeremyf))
- Add `args' param to ActiveFedora::SolrService.count [\#105](https://github.com/samvera/active_fedora/pull/105) ([dchandekstark](https://github.com/dchandekstark))
- habtm\#delete saves between the before and after hook. [\#104](https://github.com/samvera/active_fedora/pull/104) ([jcoyne](https://github.com/jcoyne))
- Added association delete callbacks [\#103](https://github.com/samvera/active_fedora/pull/103) ([jcoyne](https://github.com/jcoyne))
- Fix nested\_attributes handling, implement documented functionality [\#101](https://github.com/samvera/active_fedora/pull/101) ([MBO](https://github.com/MBO))
- Simplify ci task by moving startup wait into the jetty.yml [\#99](https://github.com/samvera/active_fedora/pull/99) ([jcoyne](https://github.com/jcoyne))
- Remove unnecessary environment task [\#98](https://github.com/samvera/active_fedora/pull/98) ([cjcolvar](https://github.com/cjcolvar))
- Closes \#84 [\#95](https://github.com/samvera/active_fedora/pull/95) ([dchandekstark](https://github.com/dchandekstark))
- Modify or remove tests that check for DC datastreams; deprecate Datastreams\#dc in favor of Datastreams\#datastreams\["DC"\] [\#94](https://github.com/samvera/active_fedora/pull/94) ([cjcolvar](https://github.com/cjcolvar))
- Issue 87 solr query [\#93](https://github.com/samvera/active_fedora/pull/93) ([cbeer](https://github.com/cbeer))
- Reworking datastream id spec to be order agnostic [\#92](https://github.com/samvera/active_fedora/pull/92) ([jeremyf](https://github.com/jeremyf))
- Using Rubydora's mint for assign\_pid [\#90](https://github.com/samvera/active_fedora/pull/90) ([jeremyf](https://github.com/jeremyf))
- Fix validations unit test to pass legitimately [\#88](https://github.com/samvera/active_fedora/pull/88) ([acurley](https://github.com/acurley))

## [v6.2.0](https://github.com/samvera/active_fedora/tree/v6.2.0) (2013-06-05)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.1.1...v6.2.0)

**Closed issues:**

- AF delete example in Wiki doesn't work for me [\#77](https://github.com/samvera/active_fedora/issues/77)

**Merged pull requests:**

- Make it work with rails4 [\#82](https://github.com/samvera/active_fedora/pull/82) ([jcoyne](https://github.com/jcoyne))
- Index object state so that deleted objects \(objState=D\) can be filtered. [\#81](https://github.com/samvera/active_fedora/pull/81) ([jcoyne](https://github.com/jcoyne))
- Label is just delegated [\#80](https://github.com/samvera/active_fedora/pull/80) ([jcoyne](https://github.com/jcoyne))
- Allow passing parameters to accessor delegates [\#79](https://github.com/samvera/active_fedora/pull/79) ([jcoyne](https://github.com/jcoyne))
- Consolidating class loading with ActiveFedora.class\_from\_string method [\#76](https://github.com/samvera/active_fedora/pull/76) ([jcoyne](https://github.com/jcoyne))

## [v6.1.1](https://github.com/samvera/active_fedora/tree/v6.1.1) (2013-05-08)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.1.0...v6.1.1)

**Merged pull requests:**

- Objects loaded via Solr should have datastream properties of same class [\#74](https://github.com/samvera/active_fedora/pull/74) ([jcoyne](https://github.com/jcoyne))

## [v6.1.0](https://github.com/samvera/active_fedora/tree/v6.1.0) (2013-04-29)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v5.6.3...v6.1.0)

**Closed issues:**

- Schema has qf=active\_fedora\_model\_ssi but AF actually writes active\_fedora\_model\_ssim [\#66](https://github.com/samvera/active_fedora/issues/66)
- Active Fedora 5.6 needs a more restrictive solrizer requirement [\#61](https://github.com/samvera/active_fedora/issues/61)
- ActiveFedora::Base.exists?\(nil\) returning true [\#56](https://github.com/samvera/active_fedora/issues/56)
- Don't use predicates.yml, Use RDF::Vocabulary instead. [\#38](https://github.com/samvera/active_fedora/issues/38)

**Merged pull requests:**

- Issue \#56: ActiveFedora::Base.exists?\(nil\) returning true [\#72](https://github.com/samvera/active_fedora/pull/72) ([awead](https://github.com/awead))
- Remove extraneous solr configs [\#71](https://github.com/samvera/active_fedora/pull/71) ([jcoyne](https://github.com/jcoyne))
- Copy changes from 30feeddcb896e8ad49907a49e76f69bda1038938 into the temp... [\#69](https://github.com/samvera/active_fedora/pull/69) ([jcoyne](https://github.com/jcoyne))
- Added some sensible defaults to the solrconfig. Removed comments about old fields [\#68](https://github.com/samvera/active_fedora/pull/68) ([jcoyne](https://github.com/jcoyne))
- active\_fedora\_model solr field should not be multivalued [\#67](https://github.com/samvera/active_fedora/pull/67) ([jcoyne](https://github.com/jcoyne))
- Add ActiveFedora::Base.decendants [\#65](https://github.com/samvera/active_fedora/pull/65) ([jcoyne](https://github.com/jcoyne))
- Fixed fields for solrconfig permissions [\#64](https://github.com/samvera/active_fedora/pull/64) ([jcoyne](https://github.com/jcoyne))
- Deprecate get\_values\_from\_datastream. Fixes \#52 [\#63](https://github.com/samvera/active_fedora/pull/63) ([jcoyne](https://github.com/jcoyne))
- Deprecate Attributes\#update\_datastream\_attributes [\#62](https://github.com/samvera/active_fedora/pull/62) ([jcoyne](https://github.com/jcoyne))
- Use class\_attribute for delegate registry so inheritance works. Fixes \#59 [\#60](https://github.com/samvera/active_fedora/pull/60) ([jcoyne](https://github.com/jcoyne))
- new ActiveFedora::Auditable mixin - provides access to Fedora audit trail [\#58](https://github.com/samvera/active_fedora/pull/58) ([jcoyne](https://github.com/jcoyne))
- Make the deprecation message more helpful [\#57](https://github.com/samvera/active_fedora/pull/57) ([jcoyne](https://github.com/jcoyne))
- remove @owner.new\_record? check from the association collection append o... [\#54](https://github.com/samvera/active_fedora/pull/54) ([cbeer](https://github.com/cbeer))
- Fix has and belogns to many, so it calls remove\_relationship on the righ... [\#53](https://github.com/samvera/active_fedora/pull/53) ([cbeer](https://github.com/cbeer))
- Add jetty.yml to solr generator to overwrite the Blacklight jetty.yml. [\#30](https://github.com/samvera/active_fedora/pull/30) ([jkeck](https://github.com/jkeck))

## [v5.6.3](https://github.com/samvera/active_fedora/tree/v5.6.3) (2013-04-11)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.0.0...v5.6.3)

**Fixed bugs:**

- AF 6.0.0 delegate/delegate\_to breaks if model is not direct subclass of AF::Base [\#59](https://github.com/samvera/active_fedora/issues/59)

**Closed issues:**

- Deprecate Attribute\#get\_values\_from\_datastream [\#52](https://github.com/samvera/active_fedora/issues/52)

## [v6.0.0](https://github.com/samvera/active_fedora/tree/v6.0.0) (2013-03-28)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.0.0.rc7...v6.0.0)

## [v6.0.0.rc7](https://github.com/samvera/active_fedora/tree/v6.0.0.rc7) (2013-03-26)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.0.0.rc6...v6.0.0.rc7)

**Merged pull requests:**

- Extracting object from .load\_instance\_from\_solr [\#51](https://github.com/samvera/active_fedora/pull/51) ([jeremyf](https://github.com/jeremyf))

## [v6.0.0.rc6](https://github.com/samvera/active_fedora/tree/v6.0.0.rc6) (2013-03-12)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.0.0.rc5...v6.0.0.rc6)

**Closed issues:**

- Save ends up creating OmDatastreams with template content even though they haven't been accessed. [\#39](https://github.com/samvera/active_fedora/issues/39)

## [v6.0.0.rc5](https://github.com/samvera/active_fedora/tree/v6.0.0.rc5) (2013-03-07)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.0.0.rc4...v6.0.0.rc5)

**Closed issues:**

- OmDatastream should not store default templates [\#50](https://github.com/samvera/active_fedora/issues/50)
- Should we switch default controGroup to 'M' [\#49](https://github.com/samvera/active_fedora/issues/49)

## [v6.0.0.rc4](https://github.com/samvera/active_fedora/tree/v6.0.0.rc4) (2013-02-25)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.0.0.rc3...v6.0.0.rc4)

**Merged pull requests:**

- Updating to enable HTTP request with webmock [\#46](https://github.com/samvera/active_fedora/pull/46) ([jeremyf](https://github.com/jeremyf))
- Updating explicit path for rspec matchers [\#45](https://github.com/samvera/active_fedora/pull/45) ([jeremyf](https://github.com/jeremyf))
- Adding \#match\_fedora\_datastream rspec matcher [\#44](https://github.com/samvera/active_fedora/pull/44) ([jeremyf](https://github.com/jeremyf))

## [v6.0.0.rc3](https://github.com/samvera/active_fedora/tree/v6.0.0.rc3) (2013-02-22)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.0.0.rc2...v6.0.0.rc3)

## [v6.0.0.rc2](https://github.com/samvera/active_fedora/tree/v6.0.0.rc2) (2013-02-15)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.0.0.rc1...v6.0.0.rc2)

## [v6.0.0.rc1](https://github.com/samvera/active_fedora/tree/v6.0.0.rc1) (2013-02-15)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v5.6.2...v6.0.0.rc1)

**Closed issues:**

- datastream should have an .external? method [\#40](https://github.com/samvera/active_fedora/issues/40)

## [v5.6.2](https://github.com/samvera/active_fedora/tree/v5.6.2) (2013-02-06)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v5.6.1...v5.6.2)

## [v5.6.1](https://github.com/samvera/active_fedora/tree/v5.6.1) (2013-02-04)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.0.0.pre10...v5.6.1)

## [v6.0.0.pre10](https://github.com/samvera/active_fedora/tree/v6.0.0.pre10) (2013-02-04)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.0.0.pre9...v6.0.0.pre10)

## [v6.0.0.pre9](https://github.com/samvera/active_fedora/tree/v6.0.0.pre9) (2013-02-03)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v5.6.0...v6.0.0.pre9)

## [v5.6.0](https://github.com/samvera/active_fedora/tree/v5.6.0) (2013-02-02)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.0.0.pre8...v5.6.0)

## [v6.0.0.pre8](https://github.com/samvera/active_fedora/tree/v6.0.0.pre8) (2013-02-02)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.0.0.pre7...v6.0.0.pre8)

**Closed issues:**

- ActiveFedora::Base.delete\_all should return a count, not a list of objects. [\#32](https://github.com/samvera/active_fedora/issues/32)

## [v6.0.0.pre7](https://github.com/samvera/active_fedora/tree/v6.0.0.pre7) (2013-01-30)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v5.5.2...v6.0.0.pre7)

**Closed issues:**

- Regression in behavior of AF::Base\#find when using :sort option. [\#35](https://github.com/samvera/active_fedora/issues/35)

## [v5.5.2](https://github.com/samvera/active_fedora/tree/v5.5.2) (2013-01-28)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.0.0.pre6...v5.5.2)

**Closed issues:**

- Warn about multiple has\_many relationships on one model sharing a predicate, or allow them to produce a solr query that can discriminate on the class\_name attribute [\#25](https://github.com/samvera/active_fedora/issues/25)

## [v6.0.0.pre6](https://github.com/samvera/active_fedora/tree/v6.0.0.pre6) (2013-01-27)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.0.0.pre5...v6.0.0.pre6)

## [v6.0.0.pre5](https://github.com/samvera/active_fedora/tree/v6.0.0.pre5) (2013-01-26)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.0.0.pre4...v6.0.0.pre5)

## [v6.0.0.pre4](https://github.com/samvera/active_fedora/tree/v6.0.0.pre4) (2013-01-25)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.0.0.pre3...v6.0.0.pre4)

## [v6.0.0.pre3](https://github.com/samvera/active_fedora/tree/v6.0.0.pre3) (2013-01-25)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.0.0.pre2...v6.0.0.pre3)

## [v6.0.0.pre2](https://github.com/samvera/active_fedora/tree/v6.0.0.pre2) (2013-01-24)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v5.5.1...v6.0.0.pre2)

## [v5.5.1](https://github.com/samvera/active_fedora/tree/v5.5.1) (2013-01-24)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v6.0.0.pre1...v5.5.1)

**Closed issues:**

- RdfNode.rdf\_type doesn't work when you pass a RDF::URI [\#34](https://github.com/samvera/active_fedora/issues/34)

## [v6.0.0.pre1](https://github.com/samvera/active_fedora/tree/v6.0.0.pre1) (2013-01-23)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v5.5.0...v6.0.0.pre1)

## [v5.5.0](https://github.com/samvera/active_fedora/tree/v5.5.0) (2013-01-18)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v5.5.0.rc2...v5.5.0)

**Merged pull requests:**

- First cut at a complex rdf document.   [\#29](https://github.com/samvera/active_fedora/pull/29) ([jcoyne](https://github.com/jcoyne))

## [v5.5.0.rc2](https://github.com/samvera/active_fedora/tree/v5.5.0.rc2) (2013-01-17)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v5.5.0.rc1...v5.5.0.rc2)

## [v5.5.0.rc1](https://github.com/samvera/active_fedora/tree/v5.5.0.rc1) (2013-01-15)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v5.4.0...v5.5.0.rc1)

**Merged pull requests:**

- NomDatastream should allow options on set\_terminology [\#28](https://github.com/samvera/active_fedora/pull/28) ([jeremyf](https://github.com/jeremyf))
- nom-xml gem should be in gemspec [\#27](https://github.com/samvera/active_fedora/pull/27) ([jeremyf](https://github.com/jeremyf))

## [v5.4.0](https://github.com/samvera/active_fedora/tree/v5.4.0) (2013-01-07)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v5.3.1...v5.4.0)

**Merged pull requests:**

- Added delegate to is\_a? for RDF [\#23](https://github.com/samvera/active_fedora/pull/23) ([carolyncole](https://github.com/carolyncole))

## [v5.3.1](https://github.com/samvera/active_fedora/tree/v5.3.1) (2012-12-20)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v5.3.0...v5.3.1)

## [v5.3.0](https://github.com/samvera/active_fedora/tree/v5.3.0) (2012-12-20)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v5.2.1...v5.3.0)

## [v5.2.1](https://github.com/samvera/active_fedora/tree/v5.2.1) (2012-12-12)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v5.2.0...v5.2.1)

## [v5.2.0](https://github.com/samvera/active_fedora/tree/v5.2.0) (2012-12-11)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v5.1.0...v5.2.0)

## [v5.1.0](https://github.com/samvera/active_fedora/tree/v5.1.0) (2012-12-07)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v5.0.0...v5.1.0)

**Merged pull requests:**

- Adding active\_fedora:model generator [\#16](https://github.com/samvera/active_fedora/pull/16) ([jeremyf](https://github.com/jeremyf))
- Adding generator for fedora and solr config [\#15](https://github.com/samvera/active_fedora/pull/15) ([jeremyf](https://github.com/jeremyf))
- Adding AF::Base\#reload [\#12](https://github.com/samvera/active_fedora/pull/12) ([jeremyf](https://github.com/jeremyf))

## [v5.0.0](https://github.com/samvera/active_fedora/tree/v5.0.0) (2012-11-30)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v5.0.0.rc5...v5.0.0)

## [v5.0.0.rc5](https://github.com/samvera/active_fedora/tree/v5.0.0.rc5) (2012-11-29)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v5.0.0.rc4...v5.0.0.rc5)

**Merged pull requests:**

- HYDRA-883 RDFDatastreams should handle Literals as object values [\#11](https://github.com/samvera/active_fedora/pull/11) ([no-reply](https://github.com/no-reply))

## [v5.0.0.rc4](https://github.com/samvera/active_fedora/tree/v5.0.0.rc4) (2012-11-28)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v5.0.0.rc3...v5.0.0.rc4)

**Merged pull requests:**

- Deprecating /^has\_\(bidirectional\_\)?relationship$/ [\#9](https://github.com/samvera/active_fedora/pull/9) ([jeremyf](https://github.com/jeremyf))

## [v5.0.0.rc3](https://github.com/samvera/active_fedora/tree/v5.0.0.rc3) (2012-11-15)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v5.0.0.rc2...v5.0.0.rc3)

## [v5.0.0.rc2](https://github.com/samvera/active_fedora/tree/v5.0.0.rc2) (2012-11-12)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v5.0.0.rc1...v5.0.0.rc2)

## [v5.0.0.rc1](https://github.com/samvera/active_fedora/tree/v5.0.0.rc1) (2012-10-25)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v4.6.0.rc4...v5.0.0.rc1)

## [v4.6.0.rc4](https://github.com/samvera/active_fedora/tree/v4.6.0.rc4) (2012-10-24)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v4.6.0.rc3...v4.6.0.rc4)

## [v4.6.0.rc3](https://github.com/samvera/active_fedora/tree/v4.6.0.rc3) (2012-10-14)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v4.6.0.rc2...v4.6.0.rc3)

## [v4.6.0.rc2](https://github.com/samvera/active_fedora/tree/v4.6.0.rc2) (2012-10-13)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v4.6.0.rc1...v4.6.0.rc2)

## [v4.6.0.rc1](https://github.com/samvera/active_fedora/tree/v4.6.0.rc1) (2012-10-12)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v4.5.3...v4.6.0.rc1)

## [v4.5.3](https://github.com/samvera/active_fedora/tree/v4.5.3) (2012-10-08)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v4.5.2...v4.5.3)

## [v4.5.2](https://github.com/samvera/active_fedora/tree/v4.5.2) (2012-08-30)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v4.5.1...v4.5.2)

**Merged pull requests:**

- slash-escaping forward slashes in internal\_uri's for solr 4 compat [\#8](https://github.com/samvera/active_fedora/pull/8) ([barmintor](https://github.com/barmintor))

## [v4.5.1](https://github.com/samvera/active_fedora/tree/v4.5.1) (2012-08-16)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v4.5.0...v4.5.1)

## [v4.5.0](https://github.com/samvera/active_fedora/tree/v4.5.0) (2012-07-30)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v4.4.1...v4.5.0)

## [v4.4.1](https://github.com/samvera/active_fedora/tree/v4.4.1) (2012-07-20)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v4.4.0...v4.4.1)

## [v4.4.0](https://github.com/samvera/active_fedora/tree/v4.4.0) (2012-06-29)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v4.3.0...v4.4.0)

**Merged pull requests:**

- Hydra 830 [\#6](https://github.com/samvera/active_fedora/pull/6) ([awead](https://github.com/awead))

## [v4.3.0](https://github.com/samvera/active_fedora/tree/v4.3.0) (2012-06-21)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v4.2.0...v4.3.0)

**Merged pull requests:**

- \#delegate\_to method and unit test [\#5](https://github.com/samvera/active_fedora/pull/5) ([awead](https://github.com/awead))

## [v4.2.0](https://github.com/samvera/active_fedora/tree/v4.2.0) (2012-06-12)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v4.1.0...v4.2.0)

## [v4.1.0](https://github.com/samvera/active_fedora/tree/v4.1.0) (2012-05-09)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v4.0.0...v4.1.0)

## [v4.0.0](https://github.com/samvera/active_fedora/tree/v4.0.0) (2012-04-23)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v4.0.0.rc20...v4.0.0)

**Merged pull requests:**

- Change prefix method in RDFDatastream to handle case more gracefully [\#2](https://github.com/samvera/active_fedora/pull/2) ([mjgiarlo](https://github.com/mjgiarlo))

## [v4.0.0.rc20](https://github.com/samvera/active_fedora/tree/v4.0.0.rc20) (2012-04-02)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v4.0.0.rc19...v4.0.0.rc20)

**Merged pull requests:**

- Succeed with loading from solr even if the object was missing a declared datastream [\#1](https://github.com/samvera/active_fedora/pull/1) ([mbklein](https://github.com/mbklein))

## [v4.0.0.rc19](https://github.com/samvera/active_fedora/tree/v4.0.0.rc19) (2012-03-30)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v4.0.0.rc18...v4.0.0.rc19)

## [v4.0.0.rc18](https://github.com/samvera/active_fedora/tree/v4.0.0.rc18) (2012-03-29)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v4.0.0.rc17...v4.0.0.rc18)

## [v4.0.0.rc17](https://github.com/samvera/active_fedora/tree/v4.0.0.rc17) (2012-03-29)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v4.0.0.rc16...v4.0.0.rc17)

## [v4.0.0.rc16](https://github.com/samvera/active_fedora/tree/v4.0.0.rc16) (2012-03-26)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v4.0.0.rc15...v4.0.0.rc16)

## [v4.0.0.rc15](https://github.com/samvera/active_fedora/tree/v4.0.0.rc15) (2012-03-18)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v4.0.0.rc14...v4.0.0.rc15)

## [v4.0.0.rc14](https://github.com/samvera/active_fedora/tree/v4.0.0.rc14) (2012-03-18)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v4.0.0.rc13...v4.0.0.rc14)

## [v4.0.0.rc13](https://github.com/samvera/active_fedora/tree/v4.0.0.rc13) (2012-03-16)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v4.0.0.rc12...v4.0.0.rc13)

## [v4.0.0.rc12](https://github.com/samvera/active_fedora/tree/v4.0.0.rc12) (2012-03-16)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v4.0.0.rc11...v4.0.0.rc12)

## [v4.0.0.rc11](https://github.com/samvera/active_fedora/tree/v4.0.0.rc11) (2012-03-13)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v4.0.0.rc10...v4.0.0.rc11)

## [v4.0.0.rc10](https://github.com/samvera/active_fedora/tree/v4.0.0.rc10) (2012-03-12)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v4.0.0.rc9...v4.0.0.rc10)

## [v4.0.0.rc9](https://github.com/samvera/active_fedora/tree/v4.0.0.rc9) (2012-03-08)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v4.0.0.rc8...v4.0.0.rc9)

## [v4.0.0.rc8](https://github.com/samvera/active_fedora/tree/v4.0.0.rc8) (2012-03-07)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v4.0.0.rc7...v4.0.0.rc8)

## [v4.0.0.rc7](https://github.com/samvera/active_fedora/tree/v4.0.0.rc7) (2012-03-07)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v4.0.0.rc6...v4.0.0.rc7)

## [v4.0.0.rc6](https://github.com/samvera/active_fedora/tree/v4.0.0.rc6) (2012-03-07)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v4.0.0.rc5...v4.0.0.rc6)

## [v4.0.0.rc5](https://github.com/samvera/active_fedora/tree/v4.0.0.rc5) (2012-03-07)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v4.0.0.rc4...v4.0.0.rc5)

## [v4.0.0.rc4](https://github.com/samvera/active_fedora/tree/v4.0.0.rc4) (2012-03-07)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v4.0.0.rc3...v4.0.0.rc4)

## [v4.0.0.rc3](https://github.com/samvera/active_fedora/tree/v4.0.0.rc3) (2012-03-07)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v4.0.0.rc2...v4.0.0.rc3)

## [v4.0.0.rc2](https://github.com/samvera/active_fedora/tree/v4.0.0.rc2) (2012-03-06)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v4.0.0.rc1...v4.0.0.rc2)

## [v4.0.0.rc1](https://github.com/samvera/active_fedora/tree/v4.0.0.rc1) (2012-03-04)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v3.3.2...v4.0.0.rc1)

## [v3.3.2](https://github.com/samvera/active_fedora/tree/v3.3.2) (2012-02-27)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v3.3.1...v3.3.2)

## [v3.3.1](https://github.com/samvera/active_fedora/tree/v3.3.1) (2012-02-06)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v3.3.0...v3.3.1)

## [v3.3.0](https://github.com/samvera/active_fedora/tree/v3.3.0) (2012-01-30)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v3.2.2...v3.3.0)

## [v3.2.2](https://github.com/samvera/active_fedora/tree/v3.2.2) (2012-01-20)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v3.2.0...v3.2.2)

## [v3.2.0](https://github.com/samvera/active_fedora/tree/v3.2.0) (2012-01-09)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v3.1.6...v3.2.0)

## [v3.1.6](https://github.com/samvera/active_fedora/tree/v3.1.6) (2012-01-05)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v3.2.0.pre7...v3.1.6)

## [v3.2.0.pre7](https://github.com/samvera/active_fedora/tree/v3.2.0.pre7) (2012-01-04)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v3.2.0.pre6...v3.2.0.pre7)

## [v3.2.0.pre6](https://github.com/samvera/active_fedora/tree/v3.2.0.pre6) (2012-01-03)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v3.2.0.pre5...v3.2.0.pre6)

## [v3.2.0.pre5](https://github.com/samvera/active_fedora/tree/v3.2.0.pre5) (2012-01-02)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v3.2.0.pre4...v3.2.0.pre5)

## [v3.2.0.pre4](https://github.com/samvera/active_fedora/tree/v3.2.0.pre4) (2012-01-01)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v3.2.0.pre3...v3.2.0.pre4)

## [v3.2.0.pre3](https://github.com/samvera/active_fedora/tree/v3.2.0.pre3) (2011-12-30)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v3.2.0.pre2...v3.2.0.pre3)

## [v3.2.0.pre2](https://github.com/samvera/active_fedora/tree/v3.2.0.pre2) (2011-12-29)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v3.2.0.pre1...v3.2.0.pre2)

## [v3.2.0.pre1](https://github.com/samvera/active_fedora/tree/v3.2.0.pre1) (2011-12-21)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v3.1.5...v3.2.0.pre1)

## [v3.1.5](https://github.com/samvera/active_fedora/tree/v3.1.5) (2011-12-14)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v3.1.4...v3.1.5)

## [v3.1.4](https://github.com/samvera/active_fedora/tree/v3.1.4) (2011-11-28)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v3.1.3...v3.1.4)

## [v3.1.3](https://github.com/samvera/active_fedora/tree/v3.1.3) (2011-11-18)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v3.1.2...v3.1.3)

## [v3.1.2](https://github.com/samvera/active_fedora/tree/v3.1.2) (2011-11-18)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v3.1.1...v3.1.2)

## [v3.1.1](https://github.com/samvera/active_fedora/tree/v3.1.1) (2011-11-09)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v3.1.0...v3.1.1)

## [v3.1.0](https://github.com/samvera/active_fedora/tree/v3.1.0) (2011-11-07)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v3.1.0.rc4...v3.1.0)

## [v3.1.0.rc4](https://github.com/samvera/active_fedora/tree/v3.1.0.rc4) (2011-11-02)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v3.1.0.rc3...v3.1.0.rc4)

## [v3.1.0.rc3](https://github.com/samvera/active_fedora/tree/v3.1.0.rc3) (2011-10-31)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v3.1.0.rc2...v3.1.0.rc3)

## [v3.1.0.rc2](https://github.com/samvera/active_fedora/tree/v3.1.0.rc2) (2011-10-28)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v3.1.0.rc1...v3.1.0.rc2)

## [v3.1.0.rc1](https://github.com/samvera/active_fedora/tree/v3.1.0.rc1) (2011-10-27)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v3.1.0.pre14...v3.1.0.rc1)

## [v3.1.0.pre14](https://github.com/samvera/active_fedora/tree/v3.1.0.pre14) (2011-10-27)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v3.1.0.pre13...v3.1.0.pre14)

## [v3.1.0.pre13](https://github.com/samvera/active_fedora/tree/v3.1.0.pre13) (2011-10-27)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v3.1.0.pre12...v3.1.0.pre13)

## [v3.1.0.pre12](https://github.com/samvera/active_fedora/tree/v3.1.0.pre12) (2011-10-21)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v3.1.0.pre11...v3.1.0.pre12)

## [v3.1.0.pre11](https://github.com/samvera/active_fedora/tree/v3.1.0.pre11) (2011-10-21)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v3.1.0.pre10...v3.1.0.pre11)

## [v3.1.0.pre10](https://github.com/samvera/active_fedora/tree/v3.1.0.pre10) (2011-10-20)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v3.1.0.pre9...v3.1.0.pre10)

## [v3.1.0.pre9](https://github.com/samvera/active_fedora/tree/v3.1.0.pre9) (2011-10-20)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v3.0.7...v3.1.0.pre9)

## [v3.0.7](https://github.com/samvera/active_fedora/tree/v3.0.7) (2011-10-20)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v3.0.6...v3.0.7)

## [v3.0.6](https://github.com/samvera/active_fedora/tree/v3.0.6) (2011-10-19)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v3.1.0.pre8...v3.0.6)

## [v3.1.0.pre8](https://github.com/samvera/active_fedora/tree/v3.1.0.pre8) (2011-10-18)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v3.1.0.pre7...v3.1.0.pre8)

## [v3.1.0.pre7](https://github.com/samvera/active_fedora/tree/v3.1.0.pre7) (2011-10-14)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v3.1.0.pre6...v3.1.0.pre7)

## [v3.1.0.pre6](https://github.com/samvera/active_fedora/tree/v3.1.0.pre6) (2011-10-13)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v3.1.0.pre5...v3.1.0.pre6)

## [v3.1.0.pre5](https://github.com/samvera/active_fedora/tree/v3.1.0.pre5) (2011-10-13)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v3.1.0.pre4...v3.1.0.pre5)

## [v3.1.0.pre4](https://github.com/samvera/active_fedora/tree/v3.1.0.pre4) (2011-10-13)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v3.1.0.pre3...v3.1.0.pre4)

## [v3.1.0.pre3](https://github.com/samvera/active_fedora/tree/v3.1.0.pre3) (2011-10-13)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v3.0.5...v3.1.0.pre3)

## [v3.0.5](https://github.com/samvera/active_fedora/tree/v3.0.5) (2011-10-11)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v3.1.0.pre2...v3.0.5)

## [v3.1.0.pre2](https://github.com/samvera/active_fedora/tree/v3.1.0.pre2) (2011-10-11)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v3.1.0.pre1...v3.1.0.pre2)

## [v3.1.0.pre1](https://github.com/samvera/active_fedora/tree/v3.1.0.pre1) (2011-10-11)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v2.3.8...v3.1.0.pre1)

## [v2.3.8](https://github.com/samvera/active_fedora/tree/v2.3.8) (2011-09-24)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v3.0.4...v2.3.8)

## [v3.0.4](https://github.com/samvera/active_fedora/tree/v3.0.4) (2011-09-16)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v3.0.3...v3.0.4)

## [v3.0.3](https://github.com/samvera/active_fedora/tree/v3.0.3) (2011-09-08)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v3.0.2...v3.0.3)

## [v3.0.2](https://github.com/samvera/active_fedora/tree/v3.0.2) (2011-09-08)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v3.0.1...v3.0.2)

## [v3.0.1](https://github.com/samvera/active_fedora/tree/v3.0.1) (2011-09-08)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v3.0.0...v3.0.1)

## [v3.0.0](https://github.com/samvera/active_fedora/tree/v3.0.0) (2011-09-02)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v2.3.7...v3.0.0)

## [v2.3.7](https://github.com/samvera/active_fedora/tree/v2.3.7) (2011-09-02)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v2.3.6...v2.3.7)

## [v2.3.6](https://github.com/samvera/active_fedora/tree/v2.3.6) (2011-08-31)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v2.3.5...v2.3.6)

## [v2.3.5](https://github.com/samvera/active_fedora/tree/v2.3.5) (2011-08-31)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v2.3.4...v2.3.5)

## [v2.3.4](https://github.com/samvera/active_fedora/tree/v2.3.4) (2011-08-29)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v2.3.3...v2.3.4)

## [v2.3.3](https://github.com/samvera/active_fedora/tree/v2.3.3) (2011-07-19)

[Full Changelog](https://github.com/samvera/active_fedora/compare/hydra-541...v2.3.3)

## [hydra-541](https://github.com/samvera/active_fedora/tree/hydra-541) (2011-07-18)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v2.3.1...hydra-541)

## [v2.3.1](https://github.com/samvera/active_fedora/tree/v2.3.1) (2011-07-06)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v2.3.0...v2.3.1)

## [v2.3.0](https://github.com/samvera/active_fedora/tree/v2.3.0) (2011-06-21)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v2.2.3...v2.3.0)

## [v2.2.3](https://github.com/samvera/active_fedora/tree/v2.2.3) (2011-06-17)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v2.2.2...v2.2.3)

## [v2.2.2](https://github.com/samvera/active_fedora/tree/v2.2.2) (2011-06-05)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v2.2.1...v2.2.2)

## [v2.2.1](https://github.com/samvera/active_fedora/tree/v2.2.1) (2011-05-31)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v2.2.0...v2.2.1)

## [v2.2.0](https://github.com/samvera/active_fedora/tree/v2.2.0) (2011-05-03)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v2.1.0...v2.2.0)

## [v2.1.0](https://github.com/samvera/active_fedora/tree/v2.1.0) (2011-04-08)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v2.0.4...v2.1.0)

## [v2.0.4](https://github.com/samvera/active_fedora/tree/v2.0.4) (2011-03-15)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v2.0.3...v2.0.4)

## [v2.0.3](https://github.com/samvera/active_fedora/tree/v2.0.3) (2011-03-15)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v2.0.2...v2.0.3)

## [v2.0.2](https://github.com/samvera/active_fedora/tree/v2.0.2) (2011-03-12)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v2.0.1...v2.0.2)

## [v2.0.1](https://github.com/samvera/active_fedora/tree/v2.0.1) (2011-03-12)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v2.0.0...v2.0.1)

## [v2.0.0](https://github.com/samvera/active_fedora/tree/v2.0.0) (2011-03-03)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v1.2.9...v2.0.0)

## [v1.2.9](https://github.com/samvera/active_fedora/tree/v1.2.9) (2011-01-31)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v1.2.8...v1.2.9)

## [v1.2.8](https://github.com/samvera/active_fedora/tree/v1.2.8) (2010-12-16)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v1.2.7...v1.2.8)

## [v1.2.7](https://github.com/samvera/active_fedora/tree/v1.2.7) (2010-11-13)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v1.2.6...v1.2.7)

## [v1.2.6](https://github.com/samvera/active_fedora/tree/v1.2.6) (2010-10-27)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v1.2.5...v1.2.6)

## [v1.2.5](https://github.com/samvera/active_fedora/tree/v1.2.5) (2010-10-27)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v1.2.4...v1.2.5)

## [v1.2.4](https://github.com/samvera/active_fedora/tree/v1.2.4) (2010-10-20)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v1.2.3...v1.2.4)

## [v1.2.3](https://github.com/samvera/active_fedora/tree/v1.2.3) (2010-10-18)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v1.2.2...v1.2.3)

## [v1.2.2](https://github.com/samvera/active_fedora/tree/v1.2.2) (2010-09-15)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v1.2.1...v1.2.2)

## [v1.2.1](https://github.com/samvera/active_fedora/tree/v1.2.1) (2010-09-15)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v1.2.0...v1.2.1)

## [v1.2.0](https://github.com/samvera/active_fedora/tree/v1.2.0) (2010-09-15)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v1.1.13...v1.2.0)

## [v1.1.13](https://github.com/samvera/active_fedora/tree/v1.1.13) (2010-07-16)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v1.1.11...v1.1.13)

## [v1.1.11](https://github.com/samvera/active_fedora/tree/v1.1.11) (2010-07-02)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v1.1.9...v1.1.11)

## [v1.1.9](https://github.com/samvera/active_fedora/tree/v1.1.9) (2010-07-02)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v1.1.8...v1.1.9)

## [v1.1.8](https://github.com/samvera/active_fedora/tree/v1.1.8) (2010-06-23)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v1.1.7...v1.1.8)

## [v1.1.7](https://github.com/samvera/active_fedora/tree/v1.1.7) (2010-06-23)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v1.1.6...v1.1.7)

## [v1.1.6](https://github.com/samvera/active_fedora/tree/v1.1.6) (2010-06-14)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v1.1.5...v1.1.6)

## [v1.1.5](https://github.com/samvera/active_fedora/tree/v1.1.5) (2010-05-16)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v1.1.4...v1.1.5)

## [v1.1.4](https://github.com/samvera/active_fedora/tree/v1.1.4) (2010-05-15)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v1.1.4.pre2...v1.1.4)

## [v1.1.4.pre2](https://github.com/samvera/active_fedora/tree/v1.1.4.pre2) (2010-05-15)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v1.1.2...v1.1.4.pre2)

## [v1.1.2](https://github.com/samvera/active_fedora/tree/v1.1.2) (2010-03-31)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v1.1.1...v1.1.2)

## [v1.1.1](https://github.com/samvera/active_fedora/tree/v1.1.1) (2010-03-23)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v1.1.0...v1.1.1)

## [v1.1.0](https://github.com/samvera/active_fedora/tree/v1.1.0) (2010-03-21)

[Full Changelog](https://github.com/samvera/active_fedora/compare/v1.0.9...v1.1.0)

## [v1.0.9](https://github.com/samvera/active_fedora/tree/v1.0.9) (2010-03-21)

[Full Changelog](https://github.com/samvera/active_fedora/compare/29d0c09eef32dcda4120a5bb82c23596d33363dc...v1.0.9)



\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)*
