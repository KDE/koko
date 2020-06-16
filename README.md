# Koko

Koko is a image viewer designed for desktop and touch devices.

## Contributing

Contribution are welcome. We use https://invent.kde.org/plasma-mobile/koko/.

The [KDE Community Code of Conduct](https://kde.org/code-of-conduct) is applied.

## License

This project is licensed under the LGPL-2.1-only OR LGPL-3.0-only OR
LicenseRef-KDE-Accepted-LGPL. More information can be found in the
`LICENSES` folder.

## Packaging

To build Koko, it is required to have a few files packaged with the
application. These files are licensed under the CC-BY-SA-4.0.

* http://download.geonames.org/export/dump/cities1000.zip
* http://download.geonames.org/export/dump/admin1CodesASCII.txt
* http://download.geonames.org/export/dump/admin2Codes.txt

These files need to be copied to the `src` directory. CMake will
take care of the rest.
