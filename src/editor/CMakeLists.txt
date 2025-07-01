# SPDX-FileCopyrightText: 2025 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: BSD-2-Clause

add_library(photos_editor_static STATIC
    editorhelper.cpp
    editorhelper.h
)

ecm_add_qml_module(photos_editor_static
    URI "org.kde.photos.editor"
    GENERATE_PLUGIN_SOURCE
)

ecm_target_qml_sources(photos_editor_static SOURCES
    AnimatedLoader.qml
    AnnotationEditor.qml
    AnnotationOptionsToolBarContents.qml
    AnnotationsToolBarContents.qml
    ButtonGrid.qml
    ConfirmDiscardingChange.qml
    EditorView.qml
    ImageView.qml
)

target_link_libraries(photos_editor_static PRIVATE Qt::Gui)
