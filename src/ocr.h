// SPDX-FileCopyrightText: 2025 Florian RICHER <florian.richer@protonmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <QObject>
#include <QTimer>
#include <qqmlregistration.h>

#ifdef HAVE_TESSERACT_OCR
#include <tesseract/baseapi.h>
#endif

#include "ocrtextmodel.h"

class Ocr : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool supported READ supported NOTIFY supportedChanged)
    Q_PROPERTY(bool loaded READ loaded NOTIFY loadedChanged)
    Q_PROPERTY(QStringList availableLanguages READ availableLanguages NOTIFY availableLanguagesChanged) // NOTE: Define as CONSTANT ?
    Q_PROPERTY(QStringList loadedLanguages READ loadedLanguages NOTIFY loadedLanguagesChanged)
    Q_PROPERTY(QList<OcrTextModel *> ocrResult READ ocrResult NOTIFY ocrResultChanged)

public:
    explicit Ocr(QObject *parent = nullptr);
    virtual ~Ocr();

    bool supported() const;
    bool loaded() const;
    QStringList availableLanguages() const;
    QStringList loadedLanguages() const;
    QList<OcrTextModel *> ocrResult() const;

    Q_INVOKABLE void extractText(const QString imagePath);
    Q_INVOKABLE void loadLanguage(const QString language);
    Q_INVOKABLE void unloadLanguage(const QString language);
    Q_INVOKABLE void resetOcrResult();

signals:
    void supportedChanged();
    void loadedChanged();
    void loadedLanguagesChanged();
    void availableLanguagesChanged();
    void ocrResultChanged();

private slots:
    void loadPendingLanguages();

private:
    bool m_supported = false;
    bool m_loaded = false;

    QTimer m_loadTimer;

    QStringList m_loadedLanguages = {};
    QStringList m_availableLanguages = {};
    QStringList m_pendingLanguages = {};

#ifdef HAVE_TESSERACT_OCR
    tesseract::TessBaseAPI *m_api{nullptr};
#endif
    QList<OcrTextModel::Ptr> m_ocrResult;

    bool load(const QStringList languages);
    void unload();

    void refreshAvailableLanguages();
    void refreshLoadedLanguages();
};
