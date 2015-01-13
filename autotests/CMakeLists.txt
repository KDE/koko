ecm_add_test(reversegeocodetest.cpp ../src/reversegeocodelookupjob.cpp
    TEST_NAME "reversegeocodetest"
    LINK_LIBRARIES Qt5::Test Qt5::Positioning Qt5::Network
)

ecm_add_test(reversegeocodertest.cpp ../src/reversegeocoder.cpp
    TEST_NAME "reversegeocodertest"
    LINK_LIBRARIES Qt5::Test ${KDETREE_LIBRARIES}
)
