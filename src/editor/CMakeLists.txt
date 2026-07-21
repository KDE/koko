# SPDX-FileCopyrightText: 2025 Carl Schwan <carl@carlschwan.eu>
# SPDX-License-Identifier: BSD-2-Clause

add_library(photos_editor_static STATIC)

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
    ConfirmDiscardingChanges.qml
    EditorView.qml
    ImageView.qml
)
qt_add_shaders(photos_editor_static "shaders"
    PRECOMPILE
    BATCHABLE
    OPTIMIZED
    PREFIX "/qt/qml/org/kde/photos/editor/shaders"
    FILES
        gammaadjust.vert
        gammaadjust.frag
    OUTPUTS
        gammaadjust.vert.qsb
        gammaadjust.frag.qsb
)

target_link_libraries(photos_editor_static PRIVATE Qt::Gui)
