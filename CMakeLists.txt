project(Gallery)
cmake_minimum_required(VERSION 2.8.12)

find_package(ECM 0.0.9 REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

find_package(Qt5 REQUIRED NO_MODULE COMPONENTS Qml Quick Test Positioning)
find_package(KF5 REQUIRED COMPONENTS Plasma I18n Declarative Config Baloo FileMetaData)
find_package(KVariantStore REQUIRED)

include(FeatureSummary)
include(ECMAddTests)
include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings)
include(GenerateExportHeader)

add_subdirectory(lib)
add_subdirectory(qml)

feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)
