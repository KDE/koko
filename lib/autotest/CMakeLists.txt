ecm_add_test(reversegeocodetest.cpp ../reversegeocodelookupjob.cpp
    TEST_NAME "reversegeocodetest"
    LINK_LIBRARIES Qt5::Test Qt5::Positioning Qt5::Network)
