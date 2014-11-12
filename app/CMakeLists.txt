add_executable(gallery
    main.cpp
    ../lib/imagestorage.cpp
    ../lib/reversegeocodelookupjob.cpp
    ../lib/balooimagefetcher.cpp
)

target_link_libraries(gallery
    Qt5::Quick
    Qt5::Widgets
    Qt5::Qml
    Qt5::Positioning
    KF5::ConfigCore
    KF5::Baloo
    KF5::FileMetaData
)

install(TARGETS gallery ${INSTALL_TARGETS_DEFAULT_ARGS})
