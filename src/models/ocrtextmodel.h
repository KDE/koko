// SPDX-FileCopyrightText: 2025 Florian RICHER <florian.richer@protonmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <QObject>
#include <qqmlregistration.h>

class OcrTextModel : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    QML_UNCREATABLE("Created by Ocr")

    Q_PROPERTY(int x READ x CONSTANT)
    Q_PROPERTY(int y READ y CONSTANT)
    Q_PROPERTY(int width READ width CONSTANT)
    Q_PROPERTY(int height READ height CONSTANT)
    Q_PROPERTY(float confidence READ confidence CONSTANT)
    Q_PROPERTY(QString text READ text CONSTANT)

public:
    typedef std::shared_ptr<OcrTextModel> Ptr;
    explicit OcrTextModel(int x, int y, int width, int height, float confidence, QString text, QObject *parent = nullptr);

    int x() const;
    int y() const;
    int width() const;
    int height() const;
    float confidence() const;
    QString text() const;

private:
    int m_x;
    int m_y;
    int m_width;
    int m_height;
    float m_confidence;
    QString m_text;
};
