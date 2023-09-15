/*
 * SPDX-FileCopyrightText: 2021 Arjen Hiemstra <ahiemstra@heimr.nl>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#include "displaycolorspace.h"

#ifdef HAVE_X11
#include "private/qtx11extras_p.h"
#include <QGuiApplication>
#include <xcb/xcb.h>
#include <xcb/xcb_atom.h>
#endif

DisplayColorSpace::DisplayColorSpace(QObject *parent)
    : QObject(parent)
{
    m_colorSpace = QColorSpace{QColorSpace::SRgb};
    update();
}

QColorSpace DisplayColorSpace::colorSpace() const
{
    return m_colorSpace;
}

void DisplayColorSpace::update()
{
#ifdef HAVE_X11
    if (auto *x11Application = qGuiApp->nativeInterface<QNativeInterface::QX11Application>()) {
        static const char *icc_profile = "_ICC_PROFILE";
        auto atom_cookie = xcb_intern_atom(x11Application->connection(), 0, sizeof(icc_profile), icc_profile);
        auto atom_reply = xcb_intern_atom_reply(x11Application->connection(), atom_cookie, nullptr);
        if (!atom_reply) {
            return;
        }

        auto icc_atom = atom_reply->atom;
        free(atom_reply);

        auto cookie = xcb_get_property(x11Application->connection(), // connection
                                       0, // delete
                                       QX11Info::appRootWindow(), // window
                                       icc_atom, // property
                                       XCB_ATOM_CARDINAL, // type
                                       0, // offset
                                       0); // length
        auto result = xcb_get_property_reply(x11Application->connection(), cookie, nullptr);
        if (!result) {
            return;
        }

        auto length = xcb_get_property_value_length(result);
        if (length <= 0) {
            return;
        }

        auto data = QByteArray(static_cast<const char *>(xcb_get_property_value(result)), length);
        auto colorSpace = QColorSpace::fromIccProfile(data);
        if (colorSpace.isValid()) {
            m_colorSpace = colorSpace;
        }

        free(result);
    }
#endif
}
