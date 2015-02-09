# Copyright (c) 2015, Vishesh Handa <vhanda@kde.org>
#
# Redistribution and use is allowed according to the terms of the BSD license.
# For details see the accompanying COPYING-CMAKE-SCRIPTS file.
#

find_path (KDTREE_INCLUDE_DIR NAMES kdtree.h)
find_library (KDTREE_LIBRARIES NAMES kdtree)

include (FindPackageHandleStandardArgs)
find_package_handle_standard_args (KdTree DEFAULT_MSG KDTREE_LIBRARIES KDTREE_INCLUDE_DIR)
