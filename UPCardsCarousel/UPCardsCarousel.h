//
//  UPCardsCarousel.h
//  UPCardsCarousel
//
//  Created by Paul ULRIC on 08/06/2014.
//  Copyright (c) 2014 Paul ULRIC. All rights reserved.
//

#import <UIKit/UIKit.h>



@protocol UPCardsCarouselDataSource, UPCardsCarouselDelegate;


@interface UPCardsCarousel : UIView

@property (nonatomic, unsafe_unretained) IBOutlet id<UPCardsCarouselDataSource> dataSource;
@property (nonatomic, unsafe_unretained) IBOutlet id<UPCardsCarouselDelegate> delegate;

@property (nonatomic, strong)    UIView *labelBanner;
@property (nonatomic, readwrite) NSUInteger maxVisibleCardsCount;
@property (nonatomic, readwrite) NSTimeInterval movingAnimationDuration;
@property (nonatomic, readwrite) BOOL doubleTapToTop;


- (void)reloadData;
- (void)reloadDataWithCurrentIndex:(NSUInteger)index;
- (void)reloadNumberOfCards;

- (UIView*)cardAtIndex:(NSUInteger)index;
- (void)updateCardContentAtIndex:(NSUInteger)index;

- (void)setLabelFont:(UIFont *)font;
- (void)setLabelTextColor:(UIColor*)color;

@end


/*
    UPCardsCarousel DataSource Protocol
*/
@protocol UPCardsCarouselDataSource <NSObject>

@required
- (NSUInteger)numberOfCardsInCarousel:(UPCardsCarousel *)carousel;
- (UIView *)carousel:(UPCardsCarousel *)carousel viewForCardAtIndex:(NSUInteger)index;

@optional
- (NSString *)carousel:(UPCardsCarousel *)carousel titleForCardAtIndex:(NSUInteger)index;

@end


/* 
    UPCardsCarousel Delegate Protocol
*/
@protocol UPCardsCarouselDelegate <NSObject>

@optional
- (void)carousel:(UPCardsCarousel *)carousel didTouchCardAtIndex:(NSUInteger)index;
//- (void)carousel:(UPCardsCarousel *)carousel willDisplayCardAtIndex:(NSUInteger)index;
- (void)carousel:(UPCardsCarousel *)carousel didDisplayCardAtIndex:(NSUInteger)index;
//- (void)carousel:(UPCardsCarousel *)carousel willHideCardAtIndex:(NSUInteger)index;
- (void)carousel:(UPCardsCarousel *)carousel didHideCardAtIndex:(NSUInteger)index;

@end