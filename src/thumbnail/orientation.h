#pragma once

/* Explanation extracted from http://sylvana.net/jpegcrop/exif_orientation.html

   For convenience, here is what the letter F would look like if it were tagged
correctly and displayed by a program that ignores the orientation tag (thus
showing the stored image):

  1        2       3      4         5            6           7          8

888888  888888      88  88      8888888888  88                  88  8888888888
88          88      88  88      88  88      88  88          88  88      88  88
8888      8888    8888  8888    88          8888888888  8888888888          88
88          88      88  88
88          88  888888  888888

*/

enum class Orientation {
    NOT_AVAILABLE = 0,
    NORMAL = 1,
    HFLIP = 2,
    ROT_180 = 3,
    VFLIP = 4,
    TRANSPOSE = 5,
    ROT_90 = 6,
    TRANSVERSE = 7,
    ROT_270 = 8,
};
