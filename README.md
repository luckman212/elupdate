# elupdater

Updater for the [Eclectic Light app library](https://eclecticlight.co/updates-sierra-and-high-sierra/) (in bash). The reference file used for version checks is https://github.com/hoakleyelc/updates/blob/master/eclecticapps.plist

#### Install

[Download](https://github.com/luckman212/elupdater/archive/master.zip) and unzip.

#### Configure

Edit `eclecticlight_config.txt` and add/remove any apps you wish to keep updated. This is a simple text file, one line per app. The format of this file is:
```
AppName|RealAppName|zipname|LatestVerOverride
```

- `AppName` should match the value of the `<AppName>` key from the eclecticapps.plist link above, e.g. `T2M2`
- `RealAppName` is the name of the actual App after it's unzipped (e.g. **TheTimeMachineMechanic.app**)
- `zipname` is the name of the .zip file in the `<URL>` key without version number, e.g. `t2m2`
- `LatestVerOverride` is an optional field, to specify a version manually in case the .plist is missing data for a certain app (e.g. KeychainCheck2)

You can edit the main `elupdate.sh` script and change the line that begins with `DST_FOLDER=` to choose a different destination directory in which to install the apps. The default is `~/Applications`.

#### Run

```bash
$ bash elupdate.sh
```
Your destination folder should now be populated with the latest versions of the apps. Schedule this script as a LaunchAgent (see https://www.launchd.info/) to keep the apps updated automatically.
