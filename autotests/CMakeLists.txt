ecm_add_test(reversegeocodertest.cpp ../src/reversegeocoder.cpp ../src/kdtree.c
    TEST_NAME "reversegeocodertest"
    LINK_LIBRARIES Qt5::Test
)
