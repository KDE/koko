# SPDX-FileCopyrightText: 2026 Jan Rathmann <jan.rathmann@gmx.de>
# SPDX-License-Identifier: BSD-2-Clause

add_library(photos_settings_static STATIC
    mimetypeshelper.h
    mimetypeshelper.cpp
)

kconfig_target_kcfg_file(photos_settings_static
    FILE kokoconfig.kcfg
    CLASS_NAME Config
    MUTATORS
    GENERATE_PROPERTIES
    GENERATE_MOC
    DEFAULT_VALUE_GETTERS
    SINGLETON
    QML_REGISTRATION
    GLOBAL_ENUMS
)

kconfig_target_kcfg_file(photos_settings_static
    FILE kokostateconfig.kcfg
    CLASS_NAME State
    MUTATORS
    GENERATE_PROPERTIES
    GENERATE_MOC
    DEFAULT_VALUE_GETTERS
    SINGLETON
    QML_REGISTRATION
)

target_link_libraries(photos_settings_static PUBLIC
    KF6::ConfigGui
    KF6::ConfigCore
    KF6::ConfigWidgets
    KF6::I18n
)

ecm_add_qml_module(photos_settings_static
    URI "org.kde.photos.settings"
    GENERATE_PLUGIN_SOURCE
)
