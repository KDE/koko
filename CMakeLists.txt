project(Koko)
cmake_minimum_required(VERSION 2.8.12)

find_package(ECM 5.53.0 REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake" ${ECM_MODULE_PATH})

find_package(Qt5 REQUIRED NO_MODULE COMPONENTS Qml Quick Widgets Test Sql Positioning)

if(ANDROID)
    find_package(Qt5 REQUIRED NO_MODULE COMPONENTS AndroidExtras)
endif()

find_package(KF5 5.5 REQUIRED COMPONENTS I18n Declarative Config KIO GuiAddons CoreAddons Notifications)
find_package(LibExiv2 0.21 REQUIRED)

include(FeatureSummary)
include(ECMAddTests)
include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings)
include(GenerateExportHeader)
include(ECMInstallIcons)

include_directories(
  ${CMAKE_SOURCE_DIR}
  ${CMAKE_SOURCE_DIR}/src
  ${CMAKE_BINARY_DIR}/src
)

kde_enable_exceptions()

add_subdirectory(src)
add_subdirectory(autotests)
add_subdirectory(icons)

install(FILES org.kde.koko.appdata.xml DESTINATION ${KDE_INSTALL_METAINFODIR})

feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)
