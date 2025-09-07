/* SPDX-FileCopyrightText: 2025 Noah Davis <noahadvs@gmail.com>
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

#include "printerhelper.h"

#include <QDebug>
#ifdef HAVE_PRINTSUPPORT
#include <QPainter>
#include <QWindow>
#include <QtPrintSupport/QPrintDialog>
#include <QtPrintSupport/QPrinter>
#endif

PrinterHelper::PrinterHelper(QObject *parent)
    : QObject(parent)
{
}

bool PrinterHelper::printerSupportAvailable()
{
#ifdef HAVE_PRINTSUPPORT
    return true;
#else
    return false;
#endif
}

void PrinterHelper::printFileFromUrl([[maybe_unused]] const QUrl &fileUrl, [[maybe_unused]] QWindow *parent)
{
#ifdef HAVE_PRINTSUPPORT
    if (!fileUrl.isLocalFile()) {
        qWarning() << "Failed to print: not a local file";
        return;
    }
    auto printer = std::make_shared<QPrinter>(QPrinter::HighResolution);
    auto dialog = new QPrintDialog(printer.get());
    dialog->setAttribute(Qt::WA_DeleteOnClose);

    // properly set the transientparent chain
    if (dialog && dialog->winId() && parent && parent->winId()) {
        dialog->windowHandle()->setTransientParent(parent);
    }

    connect(dialog, &QDialog::finished, dialog, [fileUrl, printer](int result) {
        if (result == QDialog::Rejected) {
            return;
        }
        QPainter painter;
        if (!painter.begin(printer.get())) {
            return;
        }
        painter.setRenderHint(QPainter::LosslessImageRendering);
        auto pageRect = printer->pageRect(QPrinter::DevicePixel).toRect();
        auto scaledImage = QImage(fileUrl.toLocalFile()).scaled(pageRect.size(), Qt::KeepAspectRatio, Qt::SmoothTransformation);
        auto rect = scaledImage.rect();
        rect.moveCenter(pageRect.center());
        painter.drawImage(rect.topLeft(), scaledImage);
        painter.end();
    });

    dialog->setVisible(true);
#else
    qWarning() << "Failed to print: print support is not available";
#endif
}
