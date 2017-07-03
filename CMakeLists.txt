project(Koko)
cmake_minimum_required(VERSION 2.8.12)

find_package(ECM 0.0.9 REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake" ${ECM_MODULE_PATH})

find_package(Qt5 REQUIRED NO_MODULE COMPONENTS Qml Quick Widgets Test Sql Positioning)
find_package(KF5 5.5 REQUIRED COMPONENTS I18n Declarative Config DBusAddons KIO GuiAddons)
find_package(Exiv2 0.21 REQUIRED)

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
  ${EXIV2_INCLUDE_DIR}
)

kde_enable_exceptions()

add_subdirectory(src)
add_subdirectory(autotests)
add_subdirectory(qmlUiKirigami)
add_subdirectory(icons)

feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)
