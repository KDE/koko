#include <qqmlregistration.h>

#include <KFileItem>

class KFileItemForeign
{
    Q_GADGET
    QML_FOREIGN(KFileItem)
    QML_VALUE_TYPE(fileItem)
};

class KFileItemListForeign
{
    Q_GADGET
    QML_ANONYMOUS
    QML_FOREIGN(KFileItemList)
    QML_SEQUENTIAL_CONTAINER(KFileItem)
};
