//
//  NGVaryingGridView.m
//  NGVaryingGridView
//
//  Created by Philip Messlehner on 19.04.12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//

#import "NGVaryingGridView.h"

@interface NGVaryingGridView () <UIScrollViewDelegate> {
    BOOL _topStickyViewOnHierarchyTop;
}

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) NSArray *gridRects;
@property (nonatomic, strong) NSMutableDictionary *gridCells;
@property (nonatomic, strong) NSMutableSet *reuseableCells;

@property (nonatomic, strong) UIView *stickyViewForTopPosition;
@property (nonatomic, strong) UIView *stickyViewForLeftPosition;
@property (nonatomic) CGFloat stickyViewForTopPositionPadding;
@property (nonatomic) CGFloat stickyViewForLeftPositionPadding;

- (void)loadCellsInRect:(CGRect)rect;
- (void)handleTap:(UIGestureRecognizer *)gestureRecognizer;
- (void)updateStickyViewsPosition;
- (void)bringScrollingIndicatorsToFront;

@end

@implementation NGVaryingGridView

@synthesize scrollViewDelegate = _scrollViewDelegate;
@synthesize gridViewDelegate = _gridViewDelegate;
@synthesize scrollView = _scrollView;
@synthesize gridRects = _gridRects;
@synthesize gridCells = _gridCells;
@synthesize reuseableCells = _reuseableCells;

@synthesize maximumContentWidth = _maximumContentWidth;
@synthesize maximumContentHeight = _maximumContentHeight;

@synthesize stickyViewForTopPosition = _stickyViewForTopPosition;
@synthesize stickyViewForLeftPosition = _stickyViewForLeftPosition;
@synthesize stickyViewForLeftPositionPadding = _stickyViewForLeftPositionPadding;
@synthesize stickyViewForTopPositionPadding = _stickyViewForTopPositionPadding;

////////////////////////////////////////////////////////////////////////
#pragma mark - Life Cycle
////////////////////////////////////////////////////////////////////////

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _scrollView.directionalLockEnabled = YES;
        _gridCells = [NSMutableDictionary dictionary];
        _reuseableCells = [NSMutableSet set];
        _maximumContentHeight = CGFLOAT_MAX;
        _maximumContentWidth = CGFLOAT_MAX;
        
        [super addSubview:_scrollView];
        _scrollView.delegate = self;
    }
    return self;
}

- (void)dealloc {
    _scrollView.delegate = nil;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - UIView
////////////////////////////////////////////////////////////////////////

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    if (newSuperview != nil) {
        [self reloadData];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self loadCellsInRect:self.visibleRect];
    [self updateStickyViewsPosition];
    [self bringScrollingIndicatorsToFront];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - PVTVGridView
////////////////////////////////////////////////////////////////////////

- (void)setGridViewDelegate:(id<NGVaryingGridViewDelegate>)gridViewDelegate {
    if (gridViewDelegate != _gridViewDelegate) {
        _gridViewDelegate = gridViewDelegate;
        [self reloadData];
    }
}

- (void)reloadData {
    if (_gridViewDelegate && self.superview != nil) {
        CGFloat maxX = 0.f;
        CGFloat maxY = 0.f;
        
        self.gridRects = [self.gridViewDelegate rectsForCellsInGridView:self];
        [self.gridCells.allValues makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [self.reuseableCells addObjectsFromArray:self.gridCells.allValues];
        [self.gridCells removeAllObjects];
        
        for (NSValue *rectValue in self.gridRects) {
            CGRect rect = [rectValue CGRectValue];
            maxX = MAX(maxX, rect.origin.x + rect.size.width);
            maxY = MAX(maxY, rect.origin.y + rect.size.height);
        }
        maxX = MAX(MIN(maxX, self.maximumContentWidth), self.contentSize.width);
        maxY = MAX(MIN(maxY, self.maximumContentHeight), self.contentSize.height);
        self.scrollView.contentSize = CGSizeMake(maxX, maxY);
        
        [self loadCellsInRect:self.visibleRect];
        [self updateStickyViewsPosition];
    }
}

- (UIView *)gridCellWithCGPoint:(CGPoint)point {
    for (UIView *view in self.gridCells.allValues) {
        if (CGRectContainsPoint(view.frame, point)) {
            return view;
        }
    }
    
    return nil;
}

- (void)addOverlayView:(UIView *)overlayView {
    [super addSubview:overlayView];
}

- (void)setStickyView:(UIView *)view lockPosition:(NGVaryingGridViewLockPosition)lockPosition {
    switch (lockPosition) {
        case NGVaryingGridViewLockPositionTop:
            [self.stickyViewForTopPosition removeFromSuperview];
            self.stickyViewForTopPositionPadding = view.frame.origin.y;
            self.stickyViewForTopPosition = view;
            _topStickyViewOnHierarchyTop = YES;
            break;
            
        case NGVaryingGridViewLockPositionLeft:
            [self.stickyViewForLeftPosition removeFromSuperview];
            self.stickyViewForLeftPositionPadding = view.frame.origin.x;
            self.stickyViewForLeftPosition = view;
            _topStickyViewOnHierarchyTop = NO;
            break;
            
        default:
            break;
    }
    
    [self.scrollView addSubview:view];
    [self updateStickyViewsPosition];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - PVTVGridView (Private Methods)
////////////////////////////////////////////////////////////////////////

- (void)handleTap:(UIGestureRecognizer *)gestureRecognizer {
    if ([self.gridViewDelegate respondsToSelector:@selector(gridView:didSelectCell:index:)]) {
        [self.gridViewDelegate gridView:self didSelectCell:gestureRecognizer.view index:[self.gridRects indexOfObject:[NSValue valueWithCGRect:gestureRecognizer.view.frame]]];
    }
}

- (void)loadCellsInRect:(CGRect)rect {
    NSUInteger index = 0;
    NSMutableDictionary *usedCells = [NSMutableDictionary dictionary];
    for (NSValue *rectValue in self.gridRects) {
        CGRect rectOfValue = [rectValue CGRectValue];
        if (!CGRectIsEmpty(CGRectIntersection(rect, rectOfValue))) {
            UIView *gridViewCell = [self.gridCells objectForKey:rectValue];
            if (gridViewCell == nil) {
                gridViewCell = [self.gridViewDelegate gridView:self viewForCellWithRect:rectOfValue index:index];
                gridViewCell.userInteractionEnabled = YES;
                [gridViewCell addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)]];
                [self.gridCells setObject:gridViewCell forKey:rectValue];
            }
            
            [usedCells setObject:gridViewCell forKey:rectValue];
            [self.scrollView addSubview:gridViewCell];
        }
        index ++;
    }
    
    // Move unused Cells to reusableCells
    NSMutableDictionary *unusedCells = [NSMutableDictionary dictionaryWithDictionary:self.gridCells];
    [unusedCells removeObjectsForKeys:usedCells.allKeys];
    [unusedCells.allValues makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    [self.gridCells removeObjectsForKeys:unusedCells.allKeys];
    [self.reuseableCells addObjectsFromArray:unusedCells.allValues];
}

- (UIView *)dequeueReusableCell {
    return [self dequeueReusableCellWithFrame:CGRectZero];
}

- (UIView *)dequeueReusableCellWithFrame:(CGRect)frame {
    UIView *reusableCell = [self.reuseableCells anyObject];
    if (reusableCell) {
        if ([self.gridViewDelegate respondsToSelector:@selector(gridView:willPrepareCellForReuse:)]) {
            [self.gridViewDelegate gridView:self willPrepareCellForReuse:reusableCell];
        }
        [self.reuseableCells removeObject:reusableCell];
    }
    reusableCell.frame = frame;
    return reusableCell;
}

- (void)updateStickyViewsPosition {
    self.stickyViewForTopPosition.frame = CGRectMake(self.stickyViewForTopPosition.frame.origin.x, self.scrollView.contentOffset.y + self.stickyViewForTopPositionPadding, self.stickyViewForTopPosition.frame.size.width, self.stickyViewForTopPosition.frame.size.height);
    self.stickyViewForLeftPosition.frame = CGRectMake(self.scrollView.contentOffset.x + self.stickyViewForLeftPositionPadding, self.stickyViewForLeftPosition.frame.origin.y, self.stickyViewForLeftPosition.frame.size.width, self.stickyViewForLeftPosition.frame.size.height);
    
    if (_topStickyViewOnHierarchyTop) {
        [self.scrollView bringSubviewToFront:self.stickyViewForLeftPosition];
        [self.scrollView bringSubviewToFront:self.stickyViewForTopPosition];
    } else {
        [self.scrollView bringSubviewToFront:self.stickyViewForTopPosition];
        [self.scrollView bringSubviewToFront:self.stickyViewForLeftPosition];
    }
}

- (void)bringScrollingIndicatorsToFront {
    // ScrollIndicator will hide underneath view when you are adding Subviews while Scrolling
    if (self.showsHorizontalScrollIndicator) {
        self.scrollView.showsHorizontalScrollIndicator = NO;
        self.scrollView.showsHorizontalScrollIndicator = YES;
    }
    
    if (self.showsVerticalScrollIndicator) {
        self.scrollView.showsVerticalScrollIndicator = NO;
        self.scrollView.showsVerticalScrollIndicator = YES;
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - UIScrolLView Forwarding
////////////////////////////////////////////////////////////////////////

- (void)scrollToGridCell:(UIView *)cell animated:(BOOL)animated {
    [self.scrollView scrollRectToVisible:cell.frame animated:animated];
}

- (void)scrollRectToVisible:(CGRect)rect animated:(BOOL)animated {
    [self.scrollView scrollRectToVisible:rect animated:animated];
}

- (CGRect)visibleRect {
    CGRect visibleRect;
    visibleRect.origin = self.scrollView.contentOffset;
    visibleRect.size = self.scrollView.bounds.size;
    
    float scale = 1.0 / self.scrollView.zoomScale;
    visibleRect.origin.x *= scale;
    visibleRect.origin.y *= scale;
    visibleRect.size.width *= scale;
    visibleRect.size.height *= scale;
    
    return visibleRect;
}

- (void)addSubview:(UIView *)view {
    [self.scrollView addSubview:view];
}

- (BOOL)isDirectionalLockEnabled {
    return self.scrollView.isDirectionalLockEnabled;
}

- (void)setDirectionalLockEnabled:(BOOL)directionalLockEnabled {
    self.scrollView.directionalLockEnabled = directionalLockEnabled;
}

- (void)setShowsVerticalScrollIndicator:(BOOL)showsVerticalScrollIndicator {
    self.scrollView.showsVerticalScrollIndicator = showsVerticalScrollIndicator;
}

- (BOOL)showsVerticalScrollIndicator {
    return self.scrollView.showsVerticalScrollIndicator;
}

- (void)setShowsHorizontalScrollIndicator:(BOOL)showsHorizontalScrollIndicator {
    self.scrollView.showsHorizontalScrollIndicator = showsHorizontalScrollIndicator;
}

- (BOOL)showsHorizontalScrollIndicator {
    return self.scrollView.showsHorizontalScrollIndicator;
}

- (void)setContentInset:(UIEdgeInsets)contentInset {
    self.scrollView.contentInset = contentInset;
}

- (UIEdgeInsets)contentInset {
    return self.scrollView.contentInset;
}

- (void)setContentOffset:(CGPoint)contentOffset {
    self.scrollView.contentOffset = contentOffset;
}

- (CGPoint)contentOffset {
    return self.scrollView.contentOffset;
}

- (void)setContentSize:(CGSize)contentSize {
    self.scrollView.contentSize = contentSize;
}

- (CGSize)contentSize {
    return self.scrollView.contentSize;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - UIScrollViewDelegate
////////////////////////////////////////////////////////////////////////

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([self.scrollViewDelegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
        [self.scrollViewDelegate scrollViewDidScroll:scrollView];
    }
    
    [self loadCellsInRect:self.visibleRect];
    [self updateStickyViewsPosition];
    [self bringScrollingIndicatorsToFront];
}
- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    if ([self.scrollViewDelegate respondsToSelector:@selector(scrollViewDidZoom:)]) {
        [self.scrollViewDelegate scrollViewDidZoom:scrollView];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if ([self.scrollViewDelegate respondsToSelector:@selector(scrollViewWillBeginDragging:)]) {
        [self.scrollViewDelegate scrollViewWillBeginDragging:scrollView];
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset  {
    if ([self.scrollViewDelegate respondsToSelector:@selector(scrollViewWillEndDragging:withVelocity:targetContentOffset:)]) {
        [self.scrollViewDelegate scrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if ([self.scrollViewDelegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)]) {
        [self.scrollViewDelegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    }
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    if ([self.scrollViewDelegate respondsToSelector:@selector(scrollViewWillBeginDecelerating:)]) {
        [self.scrollViewDelegate scrollViewWillBeginDecelerating:scrollView];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if ([self.scrollViewDelegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)]) {
        [self.scrollViewDelegate scrollViewDidEndDecelerating:scrollView];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if ([self.scrollViewDelegate respondsToSelector:@selector(scrollViewDidEndScrollingAnimation:)]) {
        [self.scrollViewDelegate scrollViewDidEndScrollingAnimation:scrollView];
    }
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    if ([self.scrollViewDelegate respondsToSelector:@selector(viewForZoomingInScrollView:)]) {
        return [self.scrollViewDelegate viewForZoomingInScrollView:scrollView];        
    }
    return nil;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    if ([self.scrollViewDelegate respondsToSelector:@selector(scrollViewWillBeginZooming:withView:)]) {
        [self.scrollViewDelegate scrollViewWillBeginZooming:scrollView withView:view];
    }
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale {
    if ([self.scrollViewDelegate respondsToSelector:@selector(scrollViewDidEndZooming:withView:atScale:)]) {
        [self.scrollViewDelegate scrollViewDidEndZooming:scrollView withView:view atScale:scale]; 
    }
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    if ([self.scrollViewDelegate respondsToSelector:@selector(scrollViewShouldScrollToTop:)]) {
        return [self.scrollViewDelegate scrollViewShouldScrollToTop:scrollView];
    }
    return YES;
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    if ([self.scrollViewDelegate respondsToSelector:@selector(scrollViewDidScrollToTop:)]) {
        [self.scrollViewDelegate scrollViewDidScrollToTop:scrollView];
    }
}

@end
