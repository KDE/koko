/*
 * SPDX-FileCopyrightText: (C) 2022 Silas Henrique <silash35@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#ifndef KOKO_KDTREE_H_
#define KOKO_KDTREE_H_

#include <QPointF>
#include <QVariantMap>
#include <cmath>
#include <memory>

/*
  Implementation of the k-dimensional tree algorithm in Qt/C++
*/

class KdNode
{
private:
    std::unique_ptr<KdNode> left;
    std::unique_ptr<KdNode> right;

public:
    QPointF point; // X, Y coordinates
    QVariantMap data;

    KdNode(QPointF p, QVariantMap d);

    void insert(KdNode *newNode, unsigned int axis);
    KdNode *findNearest(KdNode *pivot, unsigned int axis);
};

class KdTree
{
private:
    std::unique_ptr<KdNode> root;

public:
    void clear();
    void insert(double x, double y, QVariantMap &data);
    bool isEmpty() const;

    KdNode *findNearest(double x, double y);
};

#endif /* KOKO_KDTREE_H_ */
