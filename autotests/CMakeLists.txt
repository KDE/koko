# SPDX-FileCopyrightText: 2014  Vishesh Handa <vhanda@kde.org>
# SPDX-License-Identifier: LGPL-2.1-or-later

ecm_add_test(fileinfotest.cpp ../src/fileinfo.cpp
    TEST_NAME "fileinfotest"
    LINK_LIBRARIES Qt::Test Qt::Gui
)

ecm_add_test(kdtreetest.cpp ../src/kdtree.cpp
    TEST_NAME "kdtreetest"
    LINK_LIBRARIES Qt::Test
)

ecm_add_test(reversegeocodertest.cpp ../src/reversegeocoder.cpp ../src/kdtree.cpp
    TEST_NAME "reversegeocodertest"
    LINK_LIBRARIES Qt::Test
)
