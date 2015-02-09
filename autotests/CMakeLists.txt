ecm_add_test(reversegeocodertest.cpp ../src/reversegeocoder.cpp
    TEST_NAME "reversegeocodertest"
    LINK_LIBRARIES Qt5::Test ${KDTREE_LIBRARIES}
)
