// SPDX-FileCopyrightText: 2025 Florian RICHER <florian.richer@protonmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "ocrtextmodel.h"

#include <QDebug>

OcrTextModel::OcrTextModel(int x, int y, int width, int height, float confidence, QString text, QObject *parent)
    : QObject{parent}
    , m_x{x}
    , m_y{y}
    , m_width{width}
    , m_height{height}
    , m_confidence{confidence}
    , m_text{text}
{
}

int OcrTextModel::x() const
{
    return m_x;
}

int OcrTextModel::y() const
{
    return m_y;
}

int OcrTextModel::width() const
{
    return m_width;
}

int OcrTextModel::height() const
{
    return m_height;
}

float OcrTextModel::confidence() const
{
    return m_confidence;
}

QString OcrTextModel::text() const
{
    return m_text;
}
