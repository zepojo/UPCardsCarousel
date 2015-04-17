//
//  UPCardsCarousel.m
//  UPCardsCarousel
//
//  Created by Paul ULRIC on 08/06/2014.
//  Copyright (c) 2014 Paul ULRIC. All rights reserved.
//

#import "UPCardsCarousel.h"


const static NSUInteger     kMaxVisibleCardsDefault         = 6;
const static NSUInteger     kHiddenDeckZPositionOffset      = 10;
const static NSTimeInterval kMovingAnimationDurationDefault = .4f;
const static CGFloat        kLabelsContainerHeight          = 60;


@interface UPCardsCarousel() {
    UIView *_cardsContainer;
    NSMutableArray *_visibleCards;
    NSUInteger _numberOfCards;
    NSUInteger _visibleCardIndex;
    NSUInteger _visibleCardsOffset;
    
    NSUInteger _hiddenDeckZPositionOffset;
    NSUInteger _visibleDeckZPositionOffset;
    NSUInteger _movingDeckZPositionOffset;
    
    UILabel *_firstLabel;
    UILabel *_secondLabel;
    NSInteger _activeLabelIndex;
}

@end



@implementation UPCardsCarousel


- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupElements];
        [self setDefaultValues];
    }
    return self;
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupElements];
        [self setDefaultValues];
        
    }
    return self;
}

- (void)dealloc
{
    [_cardsContainer removeObserver:self forKeyPath:@"frame"];
}


- (void)setDataSource:(id<UPCardsCarouselDataSource>)dataSource
{
    if (_dataSource != dataSource) {
        _dataSource = dataSource;
        if (_dataSource) {
            [self reloadData];
        
            if([_dataSource respondsToSelector:@selector(carousel:labelForCardAtIndex:)]) {
                [self setLabelBannerPosition:_labelBannerPosition];
            }
            else {
                [_labelBanner setHidden:YES];
                [_cardsContainer setFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
            }
        }
    }
}


#pragma mark - UI Set Up

-(void) setDefaultValues
{
    [self setLabelBannerPosition:UPCardsCarouselLabelBannerLocation_bottom];
    [self setMaxVisibleCardsCount:kMaxVisibleCardsDefault];
    [self setMovingAnimationDuration:kMovingAnimationDurationDefault];
    [self setDoubleTapToTop:YES];
}


- (void)setupElements
{
    [self setupCardsView];
    _visibleCards = [NSMutableArray new];
    
    [self setupLabelsView];
}

- (void)setupCardsView
{
    CGRect frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height - kLabelsContainerHeight);
    _cardsContainer = [[UIView alloc] initWithFrame:frame];
    [_cardsContainer setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
    [_cardsContainer setBackgroundColor:[UIColor clearColor]];
    [_cardsContainer addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
    
    UISwipeGestureRecognizer *previousSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeToPrevious:)];
    [previousSwipe setDirection:UISwipeGestureRecognizerDirectionRight];
    [self addGestureRecognizer:previousSwipe];
    UISwipeGestureRecognizer *nextSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeToNext:)];
    [nextSwipe setDirection:UISwipeGestureRecognizerDirectionLeft];
    [self addGestureRecognizer:nextSwipe];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTouchCard:)];
    [self addGestureRecognizer:tap];
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didDoubleTap:)];
    [doubleTap setNumberOfTapsRequired:2];
    [self addGestureRecognizer:doubleTap];
    
    [self addSubview:_cardsContainer];
}

- (void)setupLabelsView
{
    CGRect frame = CGRectMake(0, 0, self.frame.size.width, kLabelsContainerHeight);
    _labelBanner = [[UIView alloc] initWithFrame:frame];
    [_labelBanner setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin];
    [_labelBanner setBackgroundColor:[UIColor whiteColor]];
    
    UILabel* (^setupLabel)(CGRect) = ^(CGRect frame) {
        UILabel *label = [[UILabel alloc] initWithFrame:frame];
        [label setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin];
        [label setTextColor:[UIColor blackColor]];
        [label setTextAlignment:NSTextAlignmentCenter];
        return label;
    };
    _firstLabel = setupLabel(CGRectMake(20, 0, frame.size.width-40, frame.size.height));
    _secondLabel = setupLabel(CGRectMake(frame.size.width+20, 0, frame.size.width-40, frame.size.height));
    [_labelBanner addSubview:_firstLabel];
    [_labelBanner addSubview:_secondLabel];
    
    _activeLabelIndex = 0;
    
    [self addSubview:_labelBanner];
}


#pragma mark - Data Management

- (void)reloadData
{
    [self reloadDataWithCurrentIndex:0];
}

- (void)reloadDataWithCurrentIndex:(NSUInteger)index
{
    for (UIView *card in _visibleCards) {
        [card removeFromSuperview];
    }
    [_visibleCards removeAllObjects];
    [_firstLabel setText:nil];
    [_secondLabel setText:nil];
    
    if (!_dataSource)
        return;
    
    _numberOfCards = [_dataSource numberOfCardsInCarousel:self];
    
    if(_numberOfCards <= 0)
        return;
    
    int cardsCount = (int)MIN(_numberOfCards, self.maxVisibleCardsCount);
    
    _hiddenDeckZPositionOffset = kHiddenDeckZPositionOffset;
    _visibleDeckZPositionOffset = _hiddenDeckZPositionOffset + cardsCount;
    _movingDeckZPositionOffset = _visibleDeckZPositionOffset + cardsCount;
    
    NSInteger start = index - cardsCount/2;
    NSInteger end = index + cardsCount/2;
    if(start < 0) {
        start = 0;
        end = cardsCount;
    }
    if(index + (cardsCount/2 - 1) >= _numberOfCards) {
        start = _numberOfCards - cardsCount;
        end = _numberOfCards;
    }
    
    for(NSUInteger i = start; i < end; i++) {
        UIView *card = [_dataSource carousel:self viewForCardAtIndex:i];
        [card setUserInteractionEnabled:YES];
        
        BOOL visible = (i >= index);
        [self positionCard:card toVisible:visible];
        NSUInteger offset = i - start;
        NSInteger zIndex = visible ? _visibleDeckZPositionOffset+(cardsCount-1-offset) : _hiddenDeckZPositionOffset+offset;
        [card.layer setZPosition:zIndex];
        
        [_cardsContainer insertSubview:card atIndex:0];
        
        [_visibleCards addObject:card];
    }
    _visibleCardIndex = index - start;
    _visibleCardsOffset = start;
    
    if([_dataSource respondsToSelector:@selector(carousel:labelForCardAtIndex:)]) {
        [_firstLabel setFrame:CGRectMake(20, 0, _labelBanner.frame.size.width-40, _labelBanner.frame.size.height)];
        [_secondLabel setFrame:CGRectMake(_labelBanner.frame.size.width+20, 0, _labelBanner.frame.size.width-40, _labelBanner.frame.size.height)];
        _activeLabelIndex = 0;
        
        NSString *label = [_dataSource carousel:self labelForCardAtIndex:_visibleCardIndex + _visibleCardsOffset];
        [_firstLabel setText:label];
    }
    
    if(_delegate) {
        NSUInteger displayedCardIndex = _visibleCardsOffset+_visibleCardIndex;
        if([_delegate respondsToSelector:@selector(carousel:willDisplayCardAtIndex:)])
            [_delegate carousel:self willDisplayCardAtIndex:displayedCardIndex];
        if([_delegate respondsToSelector:@selector(carousel:didDisplayCardAtIndex:)])
            [_delegate carousel:self didDisplayCardAtIndex:displayedCardIndex];
    }
}

- (void)reloadNumberOfCards
{
    _numberOfCards = [_dataSource numberOfCardsInCarousel:self];
}

- (void)reloadCardAtIndex:(NSUInteger)index
{
    NSInteger localIndex = index - _visibleCardsOffset;
    
    if(localIndex < 0 || localIndex >= [_visibleCards count])
        return;
    
    UIView *oldCard = [_visibleCards objectAtIndex:localIndex];
    UIView *newCard = [_dataSource carousel:self viewForCardAtIndex:index];
    [_visibleCards replaceObjectAtIndex:localIndex withObject:newCard];
    
    CGAffineTransform transform = [oldCard.layer affineTransform];
    [oldCard.layer setAffineTransform:CGAffineTransformIdentity];
    [newCard setFrame:[oldCard frame]];
    [newCard.layer setAffineTransform:transform];
    [newCard.layer setZPosition:[oldCard.layer zPosition]];
    [_cardsContainer addSubview:newCard];
    [oldCard removeFromSuperview];
}


- (UIView*)cardAtIndex:(NSUInteger)index
{
    NSInteger localIndex = index - _visibleCardsOffset;
    
    if(localIndex < 0 || localIndex >= [_visibleCards count])
        return nil;
    
    return [_visibleCards objectAtIndex:localIndex];
}


#pragma mark - UI Helpers

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([object isEqual:_cardsContainer] && [keyPath isEqualToString:@"frame"]) {
        /* When the cards container's frame changes, need to re-center the cards.
         * Setting a flexible top margin auto-resizing mask to the cards doesn't work.
         * So do it manually.
         */
        for(int i = 0; i < [_visibleCards count]; i++) {
            UIImageView *card = [_visibleCards objectAtIndex:i];
            CGPoint center;
            if(i < _visibleCardIndex) {
                int yOffset = arc4random()%20 - 10;
                center = CGPointMake(40-card.frame.size.width/2, _cardsContainer.frame.size.height/2 + yOffset);
            } else {
                center = CGPointMake(10+_cardsContainer.frame.size.width/2, _cardsContainer.frame.size.height/2);
            }
            [card setCenter:center];
        }
    }
}

- (void)positionCard:(UIView*)card toVisible:(BOOL)visible
{
    CGPoint center;
    if(visible) {
        center = CGPointMake(10+_cardsContainer.frame.size.width/2, _cardsContainer.frame.size.height/2);
    } else {
        int yOffset = arc4random()%20 - 10;
        center = CGPointMake(40-card.frame.size.width/2, _cardsContainer.frame.size.height/2 + yOffset);
    }
    
    int radians = arc4random()%20 - 10;
    float angle = (M_PI * (radians) / 180.0);
    [card.layer setAffineTransform:CGAffineTransformMakeRotation(angle)];
    [card setCenter:center];
}

/*
 If the max number of cards is displayed, the dataSource
 may have more cards to supply.
 When at the middle of the deck, look for an additional
 card in the dataSource. If there is one, add it under
 the visible or the hidden deck, according to the swipe way.
 */
- (void)addInfiniteCardsForWay:(NSNumber*)way
{
    // way = -1 -> previous | way = 1 -> next
    NSUInteger wayValue = [way integerValue];
    
    NSInteger newCardOffset = (wayValue == -1) ? -1 : [_visibleCards count];
    NSInteger newCardIndex = _visibleCardsOffset + newCardOffset;
    
    if((wayValue == -1 && newCardIndex >= 0) || (wayValue == 1 && newCardIndex < _numberOfCards)) {
        NSInteger oldCardIndex = (wayValue == -1) ? [_visibleCards count]-1 : 0;
        UIImageView *oldCard = [_visibleCards objectAtIndex:oldCardIndex];
        [_visibleCards removeObjectAtIndex:oldCardIndex];
        _visibleCardIndex += (wayValue*-1);
        _visibleCardsOffset += wayValue;
        
        NSUInteger newCardVisibleIndex = (wayValue == -1) ? 0 : [_visibleCards count];
        NSInteger newCardZPosition = (wayValue == -1) ? _hiddenDeckZPositionOffset-1 : _visibleDeckZPositionOffset-1;
        UIView *newCard = [_dataSource carousel:self viewForCardAtIndex:newCardIndex];
        [_visibleCards insertObject:newCard atIndex:newCardVisibleIndex];
        [newCard setUserInteractionEnabled:YES];
        [self positionCard:newCard toVisible:(wayValue == 1)];
        [newCard.layer setZPosition:newCardZPosition];
        [newCard setAlpha:0.0f];
        [_cardsContainer insertSubview:newCard atIndex:0];
        
        for(int i = 0; i < [_visibleCards count]; i++) {
            // Don't recompute the moving card z-index, it will be set at the end of the animation
            if((wayValue == -1 && i == _visibleCardIndex) || (wayValue == 1 && i == _visibleCardIndex-1))
                continue;
            UIImageView *card = [_visibleCards objectAtIndex:i];
            NSInteger zIndex = (i < _visibleCardIndex) ? _hiddenDeckZPositionOffset+i : _visibleDeckZPositionOffset+([_visibleCards count]-1-i);
            [card.layer setZPosition:zIndex];
        }
        
        [UIView animateWithDuration:self.movingAnimationDuration
                              delay:0.0f
                            options:UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             [newCard setAlpha:1.0f];
                             [oldCard setAlpha:0.0f];
                         } completion:^(BOOL finished) {
                             [oldCard removeFromSuperview];
                         }];
    }
}


#pragma mark - Cards Interactions

- (void)didSwipeToPrevious:(UISwipeGestureRecognizer*)swipeGesture
{
    if(_visibleCardIndex == 0)
        return;
    
    _visibleCardIndex--;
    
    NSUInteger displayedCardIndex = _visibleCardsOffset+_visibleCardIndex;
    NSUInteger hiddenCardIndex = displayedCardIndex+1;
    if(_delegate) {
        if([_delegate respondsToSelector:@selector(carousel:willHideCardAtIndex:)])
            [_delegate carousel:self willHideCardAtIndex:hiddenCardIndex];
        if([_delegate respondsToSelector:@selector(carousel:willDisplayCardAtIndex:)])
            [_delegate carousel:self willDisplayCardAtIndex:displayedCardIndex];
    }
    
    UIView *movedCard = [_visibleCards objectAtIndex:_visibleCardIndex];
    NSUInteger zIndex = [_visibleCards count]-1 - _visibleCardIndex;
    
    [UIView animateWithDuration:self.movingAnimationDuration
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionAllowUserInteraction
                     animations:^{
        [self positionCard:movedCard toVisible:YES];
        [movedCard.layer setZPosition:_movingDeckZPositionOffset + zIndex];
    } completion:^(BOOL finished) {
        NSUInteger movedCardIndex = [_visibleCards indexOfObject:movedCard];
        NSInteger zPosition = _visibleDeckZPositionOffset;
        if(movedCardIndex < [_visibleCards count] - 1) {
            UIView *nextCard = [_visibleCards objectAtIndex:movedCardIndex+1];
            zPosition = [nextCard.layer zPosition] + 1;
        }
        [movedCard.layer setZPosition:zPosition];
        
        if(_delegate) {
            if([_delegate respondsToSelector:@selector(carousel:didHideCardAtIndex:)])
                [_delegate carousel:self didHideCardAtIndex:hiddenCardIndex];
            if([_delegate respondsToSelector:@selector(carousel:didDisplayCardAtIndex:)])
                [_delegate carousel:self didDisplayCardAtIndex:displayedCardIndex];
        }
    }];
    
    if([_visibleCards count] == self.maxVisibleCardsCount && _visibleCardIndex < [_visibleCards count] / 2)
        [self addInfiniteCardsForWay:@-1];
    
    if([_dataSource respondsToSelector:@selector(carousel:labelForCardAtIndex:)]) {
        NSString *label = [_dataSource carousel:self labelForCardAtIndex:_visibleCardIndex + _visibleCardsOffset];
        [self performSelector:@selector(showPreviousLabelWithText:) withObject:label afterDelay:.1f];
    }
}


- (void)didSwipeToNext:(UISwipeGestureRecognizer*)swipeGesture
{
    if(_visibleCardIndex >= [_visibleCards count]-1)
        return;
    
    UIView *movedCard = [_visibleCards objectAtIndex:_visibleCardIndex];
    NSUInteger zIndex = _visibleCardIndex;
    
    _visibleCardIndex++;
    
    NSUInteger displayedCardIndex = _visibleCardsOffset+_visibleCardIndex;
    NSUInteger hiddenCardIndex = displayedCardIndex-1;
    if(_delegate) {
        if([_delegate respondsToSelector:@selector(carousel:willHideCardAtIndex:)])
            [_delegate carousel:self willHideCardAtIndex:hiddenCardIndex];
        if([_delegate respondsToSelector:@selector(carousel:willDisplayCardAtIndex:)])
            [_delegate carousel:self willDisplayCardAtIndex:displayedCardIndex];
    }
    
    [UIView animateWithDuration:self.movingAnimationDuration
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionAllowUserInteraction
                     animations:^{
        [self positionCard:movedCard toVisible:NO];
        [movedCard.layer setZPosition:_movingDeckZPositionOffset + zIndex];
    } completion:^(BOOL finished) {
        NSUInteger movedCardIndex = [_visibleCards indexOfObject:movedCard];
        NSInteger zPosition = _hiddenDeckZPositionOffset;
        if(movedCardIndex > 0 && movedCardIndex < [_visibleCards count]) {
            UIView *previousCard = [_visibleCards objectAtIndex:movedCardIndex-1];
            zPosition = [previousCard.layer zPosition] + 1;
        }
        [movedCard.layer setZPosition:zPosition];
        
        if(_delegate) {
            if([_delegate respondsToSelector:@selector(carousel:didHideCardAtIndex:)])
                [_delegate carousel:self didHideCardAtIndex:hiddenCardIndex];
            if([_delegate respondsToSelector:@selector(carousel:didDisplayCardAtIndex:)])
                [_delegate carousel:self didDisplayCardAtIndex:displayedCardIndex];
        }
    }];
    
    if([_visibleCards count] == self.maxVisibleCardsCount && _visibleCardIndex > [_visibleCards count] / 2)
        [self addInfiniteCardsForWay:@1];
    
    if([_dataSource respondsToSelector:@selector(carousel:labelForCardAtIndex:)]) {
        NSString *label = [_dataSource carousel:self labelForCardAtIndex:_visibleCardIndex + _visibleCardsOffset];
        [self performSelector:@selector(showNextLabelWithText:) withObject:label afterDelay:.1f];
    }
}

- (void)didDoubleTap:(UITapGestureRecognizer*)tapGesture
{
    if(_visibleCardIndex == 0)
        return;
    
    if(!_doubleTapToTop)
        return;
    
    CGPoint touchLocation = [tapGesture locationInView:self];
    UIView *card = [_visibleCards objectAtIndex:_visibleCardIndex - 1];
    if(CGRectContainsPoint(card.frame, touchLocation)) {
        [self reloadData];
    }
}

- (void)didTouchCard:(UITapGestureRecognizer*)tapGesture
{
    if([_visibleCards count] == 0)
        return;
    
    if(!_delegate || ![_delegate respondsToSelector:@selector(carousel:didTouchCardAtIndex:)])
        return;
    
    CGPoint touchLocation = [tapGesture locationInView:self];
    UIView *card = [_visibleCards objectAtIndex:_visibleCardIndex];
    if(CGRectContainsPoint(card.frame, touchLocation)) {
        NSUInteger index = _visibleCardsOffset + _visibleCardIndex;
        [_delegate carousel:self didTouchCardAtIndex:index];
    }
}


#pragma mark - Labels Animations

- (void)showNextLabelWithText:(NSString*)text
{
    [self showLabelWithText:text way:1];
}

- (void)showPreviousLabelWithText:(NSString*)text
{
    [self showLabelWithText:text way:-1];
}

- (void)showLabelWithText:(NSString*)text way:(int)way
{
    UILabel *activeLabel = (_activeLabelIndex == 0) ? _firstLabel : _secondLabel;
    UILabel *inactiveLabel = (_activeLabelIndex == 0) ? _secondLabel : _firstLabel;
    
    CGRect inactiveFrame = inactiveLabel.frame;
    inactiveFrame.origin.x = (self.frame.size.width * way) + 20;
    [inactiveLabel setFrame:inactiveFrame];
    
    [inactiveLabel setText:text];
    
    _activeLabelIndex = (_activeLabelIndex+1)%2;
    
    [UIView animateWithDuration:self.movingAnimationDuration
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         for(UILabel *label in @[activeLabel, inactiveLabel]) {
                             CGRect labelFrame = label.frame;
                             labelFrame.origin.x -= (self.frame.size.width * way);
                             [label setFrame:labelFrame];
                         }
                     } completion:NULL];
}


#pragma mark - Customization

- (void)setLabelFont:(UIFont *)font
{
    [_firstLabel setFont:font];
    [_secondLabel setFont:font];
}


- (void)setLabelTextColor:(UIColor*)color
{
    [_firstLabel setTextColor:color];
    [_secondLabel setTextColor:color];
}


- (void)setLabelBannerPosition:(UPCardsCarouselLabelBannerLocation_e)labelBannerPosition
{
    _labelBannerPosition = labelBannerPosition;
    
    CGRect cardsContainerFrame = _cardsContainer.frame;
    CGRect labelBannerFrame = _labelBanner.frame;
    UIViewAutoresizing resizingMarginMask;
    
    switch (_labelBannerPosition) {
        case UPCardsCarouselLabelBannerLocation_top:
            cardsContainerFrame.origin.y = kLabelsContainerHeight;
            labelBannerFrame.origin.y = 0;
            resizingMarginMask = UIViewAutoresizingFlexibleBottomMargin;
            break;
        case UPCardsCarouselLabelBannerLocation_bottom:
            cardsContainerFrame.origin.y = 0;
            labelBannerFrame.origin.y = self.frame.size.height - kLabelsContainerHeight;
            resizingMarginMask = UIViewAutoresizingFlexibleTopMargin;
            break;
    }
    
    [_cardsContainer setFrame:cardsContainerFrame];
    [_labelBanner setFrame:labelBannerFrame];
    [_labelBanner setAutoresizingMask:UIViewAutoresizingFlexibleWidth|resizingMarginMask];
}

@end
