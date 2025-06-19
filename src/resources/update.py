#!/usr/bin/env python3
#
# SPDX-FileCopyrightText: 2025 Oliver Beard <olib141@outlook.com>
# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
#

# Script to update third-party resources (reverse geocoding data) used by Koko:
#  - admin1CodesASCII.txt
#  - admin2Codes.txt
#  - cities1000.txt

# Usage: ./update.py

import requests
import zipfile
import os
import io

files = [
    {"url": "http://download.geonames.org/export/dump/admin1CodesASCII.txt", "filename": "admin1Codes.txt", "extract": False},
    {"url": "http://download.geonames.org/export/dump/admin2Codes.txt",      "filename": "admin2Codes.txt", "extract": False},
    {"url": "http://download.geonames.org/export/dump/cities1000.zip",       "filename": "cities1000.txt",  "extract": True },
]

script_dir = os.path.dirname(os.path.abspath(__file__))

for file in files:
    url = file["url"]
    filename = file["filename"]
    extract = file.get("extract", False)

    filepath = os.path.join(script_dir, filename)

    try:
        response = requests.get(url)
        response.raise_for_status()

        raw_content = response.content
        content = None

        if extract:
            # Get content from the zip
            with zipfile.ZipFile(io.BytesIO(raw_content)) as z:
                name_list = z.namelist();

                if len(name_list) != 1:
                    raise ValueError(f"{filename}: Zip file must contain exactly one file, but contains {len(name_list)}")

                content = z.read(name_list[0])
        else:
            # Content is not in any container
            content = raw_content

        # Compare and write file if different
        file_exists = os.path.exists(filepath)
        if file_exists:
            with open(filepath, 'rb') as f:
                if f.read() == content:
                    print(f"{filename}: Unchanged")
                    continue

        with open(filepath, 'wb') as f:
            f.write(content)

        print(f"{filename}: {'Updated' if file_exists else 'Created'}")

    except requests.RequestException as e:
        print(f"{filename}: Download failed with {e}")
    except zipfile.BadZipFile:
        print(f"{filename}: Not a valid zip file")
    except ValueError as ve:
        print(str(ve))
