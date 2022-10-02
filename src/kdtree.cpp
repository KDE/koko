/*
 * SPDX-FileCopyrightText: (C) 2022 Silas Henrique <silash35@gmail.com>
 *
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

#include "kdtree.h"

// Helper function that returns the squared distance between two points
double squaredDistance(QPointF &point1, QPointF &point2)
{
    double dx = fabs(point1.x() - point2.x());
    double dy = fabs(point1.y() - point2.y());

    return (dx * dx + dy * dy);
}

// Helper function that returns the node closest to the Pivot
KdNode *calculateClosest(KdNode *pivot, KdNode *p1, KdNode *p2)
{
    if (p1 == nullptr) {
        return p2;
    }
    if (p2 == nullptr) {
        return p1;
    }

    double distanceToP1 = squaredDistance(pivot->point, p1->point);
    double distanceToP2 = squaredDistance(pivot->point, p2->point);

    if (distanceToP1 < distanceToP2) {
        return p1;
    } else {
        return p2;
    }
}

// KdNode

KdNode::KdNode(QPointF p, QVariantMap d)
    : point{p}
    , data{d}
{
}

void KdNode::insert(KdNode *newNode, unsigned int axis)
{
    // Toggle axis at each depth
    unsigned int newAxis = axis == 0 ? 1 : 0;

    double newPointCurrentAxis = axis == 0 ? newNode->point.x() : newNode->point.y();
    double thisPointCurrentAxis = axis == 0 ? this->point.x() : this->point.y();

    if (newPointCurrentAxis < thisPointCurrentAxis) {
        if (this->left == nullptr) {
            this->left.reset(newNode);
        } else {
            this->left->insert(newNode, newAxis);
        }
    } else {
        if (this->right == nullptr) {
            this->right.reset(newNode);
        } else {
            this->right->insert(newNode, newAxis);
        }
    }
}

KdNode *KdNode::findNearest(KdNode *pivot, unsigned int axis)
{
    // Toggle axis at each depth
    unsigned int newAxis = axis == 0 ? 1 : 0;

    KdNode *best = this;
    KdNode *nextNode = nullptr;
    KdNode *oppositeNode = nullptr;

    double pivotPointCurrentAxis = axis == 0 ? pivot->point.x() : pivot->point.y();
    double thisPointCurrentAxis = axis == 0 ? this->point.x() : this->point.y();

    if (pivotPointCurrentAxis < thisPointCurrentAxis) {
        nextNode = this->left.get();
        oppositeNode = this->right.get();
    } else {
        nextNode = this->right.get();
        oppositeNode = this->left.get();
    }

    if (nextNode != nullptr) {
        best = calculateClosest(pivot, nextNode->findNearest(pivot, newAxis), this);
    }

    if (oppositeNode != nullptr && squaredDistance(pivot->point, best->point) > fabs(pivotPointCurrentAxis - thisPointCurrentAxis)) {
        best = calculateClosest(pivot, oppositeNode->findNearest(pivot, newAxis), best);
    }

    return best;
}

// KdTree

void KdTree::clear()
{
    this->root.reset();
}

void KdTree::insert(double x, double y, QVariantMap &data)
{
    QPointF newPoint = QPointF(x, y);
    KdNode *newNode = new KdNode(newPoint, data);
    if (this->root == nullptr) {
        this->root.reset(newNode);
    } else {
        this->root->insert(newNode, 0);
    }
}

KdNode *KdTree::findNearest(double x, double y)
{
    if (this->root == nullptr) {
        return nullptr;
    } else {
        QPointF pivotPoint = QPointF(x, y);
        KdNode pivotNode = KdNode(pivotPoint, QVariantMap());
        return this->root->findNearest(&pivotNode, 0);
    }
}

bool KdTree::isEmpty() const
{
    return this->root == nullptr;
}
