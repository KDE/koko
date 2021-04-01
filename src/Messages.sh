#! /bin/sh
#SPDX-FileCopyrightText: 2020 Yuri Chornoivan <yurchor@ukr.net>
#SPDX-License-Identifier: LGPL-2.0-or-later
$XGETTEXT `find . -name \*.cpp -o -name \*.h -o -name \*.qml` -o $podir/koko.pot
