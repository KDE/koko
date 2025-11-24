// SPDX-FileCopyrightText: 2025 Florian RICHER <florian.richer@protonmail.com>
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "ocr.h"

#include "kokoconfig.h"

#include <QDebug>
#include <QUrl>

Ocr::Ocr(QObject *parent)
    : QObject(parent)
#ifdef HAVE_TESSERACT_OCR
    , m_api{new tesseract::TessBaseAPI()}
#endif
{
    m_loadTimer.setInterval(1000);
    m_loadTimer.setSingleShot(true);
    connect(&m_loadTimer, &QTimer::timeout, this, &Ocr::loadPendingLanguages);

#ifdef HAVE_TESSERACT_OCR
    if (!m_api) {
        qCritical() << "Failed to instantiate tesseract";
        return;
    }

    m_supported = true;
    Q_EMIT supportedChanged();

    auto config = Config::self();
    const auto languages = config->languages();
    load(languages);

    // m_api->Init must be call before otherwise the API don't know the data directory
    refreshAvailableLanguages();
#else
    m_supported = false;
    Q_EMIT supportedChanged();
#endif
}

Ocr::~Ocr()
{
    unload();
}

bool Ocr::supported() const
{
    return m_supported;
}

bool Ocr::loaded() const
{
    return m_loaded;
}

QStringList Ocr::availableLanguages() const
{
    return m_availableLanguages;
}

QStringList Ocr::loadedLanguages() const
{
    return m_loadedLanguages;
}

QList<OcrTextModel *> Ocr::ocrResult() const
{
    QList<OcrTextModel *> lists;
    for (const OcrTextModel::Ptr &e : m_ocrResult) {
        lists.append(e.get());
    }
    return lists;
}

void Ocr::extractText(const QString imagePath)
{
#ifdef HAVE_TESSERACT_OCR
    if (!m_loaded) {
        qWarning() << "No language loaded. Please load a language.";
        return;
    }

    qInfo() << "Image Path to extract:" << imagePath;

    const QUrl url(imagePath);
    const QString localPath = url.toLocalFile();

    const QImage image(localPath);
    const QImage rgbImage = image.convertToFormat(QImage::Format_RGB888);
    m_api->SetImage(rgbImage.bits(), rgbImage.width(), rgbImage.height(), 3, rgbImage.bytesPerLine());
    m_api->Recognize(0);

    tesseract::ResultIterator *ri = m_api->GetIterator();
    tesseract::PageIteratorLevel level = tesseract::RIL_TEXTLINE;

    if (ri == 0) {
        qInfo() << "No text found in image";
        return;
    }

    m_ocrResult.clear();
    do {
        const char *word = ri->GetUTF8Text(level);
        float conf = ri->Confidence(level);
        int x1;
        int y1;
        int x2;
        int y2;

        ri->BoundingBox(level, &x1, &y1, &x2, &y2);

        const auto ocrTextModel = std::make_shared<OcrTextModel>(x1, y1, x2 - x1, y2 - y1, conf, QString::fromUtf8(word), this);
        m_ocrResult.append(ocrTextModel);

        delete[] word;
    } while (ri->Next(level));
    Q_EMIT ocrResultChanged();

    m_api->Clear();
#else
    Q_UNUSED(imagePath)
#endif
}

void Ocr::loadLanguage(const QString language)
{
    if (m_pendingLanguages.empty()) {
        m_pendingLanguages = m_loadedLanguages;
    }

    m_pendingLanguages.append(language);
    m_loadTimer.start();
}

void Ocr::unloadLanguage(const QString language)
{
    if (m_pendingLanguages.empty()) {
        m_pendingLanguages = m_loadedLanguages;
    }

    m_pendingLanguages.removeAll(language);
    m_loadTimer.start();
}

void Ocr::resetOcrResult()
{
    m_ocrResult.clear();
    Q_EMIT ocrResultChanged();
}

void Ocr::loadPendingLanguages()
{
    load(m_pendingLanguages);

    auto config = Config::self();
    config->setLanguages(m_pendingLanguages);
    config->save();

    m_pendingLanguages.clear();
}

bool Ocr::load(const QStringList languages)
{
#ifdef HAVE_TESSERACT_OCR
    if (m_loaded) {
        unload();
    }

    const QString joinedLanguages = languages.join("+");
    const QByteArray utf8 = joinedLanguages.toUtf8();
    const char *lang = utf8.constData();
    if (m_api->Init(NULL, lang) != 0) {
        qCritical() << "Failed to initialize tesseract";
        return false;
    }

    qInfo() << "Loaded languages:" << lang;

    m_loaded = true;
    Q_EMIT loadedChanged();

    refreshLoadedLanguages();

    return true;
#else
    Q_UNUSED(languages)
    return true;
#endif
}

void Ocr::unload()
{
#ifdef HAVE_TESSERACT_OCR
    if (!m_loaded) {
        return;
    }

    m_api->End();

    m_loaded = false;
    Q_EMIT loadedChanged();

    refreshLoadedLanguages();
#endif
}

void Ocr::refreshAvailableLanguages()
{
#ifdef HAVE_TESSERACT_OCR
    std::vector<std::string> languages;
    m_api->GetAvailableLanguagesAsVector(&languages);

    m_availableLanguages.clear();
    for (const std::string &language : languages) {
        m_availableLanguages.append(QString::fromStdString(language));
    }
    Q_EMIT availableLanguagesChanged();
#endif
}

void Ocr::refreshLoadedLanguages()
{
#ifdef HAVE_TESSERACT_OCR
    std::vector<std::string> languages;
    m_api->GetLoadedLanguagesAsVector(&languages);

    m_loadedLanguages.clear();
    for (const std::string &language : languages) {
        m_loadedLanguages.append(QString::fromStdString(language));
    }
    Q_EMIT loadedLanguagesChanged();
#endif
}
