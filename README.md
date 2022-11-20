<!--
SPDX-FileCopyrightText: 2020 Carl Schwan <carlschwan@kde.org>
SPDX-License-Identifier: CC0-1.0
-->
# Koko

Koko is an image viewer designed for desktop and touch devices.

<a href='https://flathub.org/apps/details/org.kde.koko'><img width='190px' alt='Download on Flathub' src='https://flathub.org/assets/badges/flathub-badge-i-en.png'/></a>

## Contributing

Contributions are welcome. We use https://invent.kde.org/graphics/koko/.

The [KDE Community Code of Conduct](https://kde.org/code-of-conduct) is applied.

## License

This project is licensed under the LGPL-2.1-only OR LGPL-3.0-only OR
LicenseRef-KDE-Accepted-LGPL. More information can be found in the
`LICENSES` folder.

## Packaging

To build Koko, it is required to import a few files from outside this repository.
These files are licensed under the CC-BY-4.0 and are maintained by the GeoNames project.

* http://download.geonames.org/export/dump/cities1000.zip
* http://download.geonames.org/export/dump/admin1CodesASCII.txt
* http://download.geonames.org/export/dump/admin2Codes.txt

These files need to be copied to the `src` directory. CMake will
take care of the rest.
