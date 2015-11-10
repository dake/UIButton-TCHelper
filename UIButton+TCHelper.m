//
//  UIButton+TCHelper.m
//  TCKit
//
//  Created by dake on 15/1/24.
//  Copyright (c) 2015年 Dake. All rights reserved.
//

#import "UIButton+TCHelper.h"
#import <objc/runtime.h>
#import "NSObject+Utilities.h"


@interface UIButton (TCLayoutStyle)

- (void)updateLayoutStyle;

@end

@interface TCButtonExtra : NSObject

@property (nonatomic, assign) UIEdgeInsets alignmentRectInsets;
@property (nonatomic, assign) CGFloat paddingBetweenTitleAndImage;
@property (nonatomic, strong) NSMutableDictionary *innerBackgroundColorDic;
@property (nonatomic, strong) NSMutableDictionary *borderColorDic;
@property (nonatomic, weak) UIButton *target;
@property (nonatomic, assign) TCButtonLayoutStyle layoutStyle;
@property (nonatomic, assign) BOOL isFrameObserved;

@end

@implementation TCButtonExtra

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.target || object == self.target.imageView) {
        if ([keyPath isEqualToString:@"highlighted"] || [keyPath isEqualToString:@"selected"] || [keyPath isEqualToString:@"enabled"]) {
            NSNumber *state = @(_target.state);
            self.target.backgroundColor = self.innerBackgroundColorDic[state];
            self.target.layer.borderColor = [(UIColor *)self.borderColorDic[state] CGColor];
            
        } else if ([keyPath isEqualToString:@"bounds"] || [keyPath isEqualToString:@"frame"]) {
            CGRect oldFrame = [(NSValue *)change[NSKeyValueChangeOldKey] CGRectValue];
            CGRect newFrame = [(NSValue *)change[NSKeyValueChangeNewKey] CGRectValue];
            
            if (!CGSizeEqualToSize(oldFrame.size, newFrame.size)) {
                [self.target updateLayoutStyle];
            }
        }
    }
}


@end



static char const kBtnExtraKey;

@implementation UIButton (TCHelper)

@dynamic layoutStyle;
@dynamic alignmentRectInsets;
@dynamic paddingBetweenTitleAndImage;

- (void)tc_dealloc
{
    TCButtonExtra *observer = objc_getAssociatedObject(self, &kBtnExtraKey);
    if (nil != observer) {
        if (observer.isFrameObserved) {
            [self removeFrameObserver:observer];
        }
        
        if (nil != observer.innerBackgroundColorDic || nil != observer.borderColorDic) {
            [self removeStateObserver:observer];
        }
        objc_setAssociatedObject(self, &kBtnExtraKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    [self tc_dealloc];
}

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // ARC forbids us to use a selector on dealloc, so we must trick it with NSSelectorFromString()
        [self tc_swizzle:NSSelectorFromString(@"dealloc")];
        [self tc_swizzle:@selector(setImage:forState:)];
        [self tc_swizzle:@selector(setTitle:forState:)];
        [self tc_swizzle:@selector(setAttributedTitle:forState:)];
    });
}

- (TCButtonExtra *)btnExtra
{
    TCButtonExtra *observer = objc_getAssociatedObject(self, &kBtnExtraKey);
    
    if (nil == observer) {
        observer = [[TCButtonExtra alloc] init];
        observer.target = self;
        objc_setAssociatedObject(self, &kBtnExtraKey, observer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return observer;
}

- (void)tc_setImage:(UIImage *)image forState:(UIControlState)state
{
    UIImage *oldImg = [self imageForState:state];
    [self tc_setImage:image forState:state];
    if (oldImg != image && !CGRectIsEmpty(self.frame)) {
        [self updateLayoutStyle];
    }
}

- (void)tc_setTitle:(NSString *)title forState:(UIControlState)state
{
    NSString *oldTitle = [self titleForState:state];
    [self tc_setTitle:title forState:state];
    if (![oldTitle isEqualToString:title] && !CGRectIsEmpty(self.frame)) {
        [self updateLayoutStyle];
    }
}

- (void)tc_setAttributedTitle:(NSAttributedString *)title forState:(UIControlState)state
{
    NSAttributedString *oldTitle = [self attributedTitleForState:state];
    [self tc_setAttributedTitle:title forState:state];
    if (![oldTitle isEqual:title] && !CGRectIsEmpty(self.frame)) {
        [self updateLayoutStyle];
    }
}

#pragma mark -  underline

- (void)setUnderlineAtrributedStringForState:(UIControlState)state
{
    NSMutableAttributedString *titleString = nil;
    
    NSString *title = [self titleForState:state];
    if (nil != title) {
        
        titleString = [[NSMutableAttributedString alloc] initWithString:title];
        [titleString addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:NSMakeRange(0, titleString.length)];
        UIColor *color = [self titleColorForState:state];
        if (nil == color) {
            color = [self titleColorForState:UIControlStateNormal];
        }
        if (nil != color) {
            [titleString addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, titleString.length)];
        }
    } else {
        UIColor *color = [self titleColorForState:state];
        if (nil != color) {
            title = [self titleForState:UIControlStateNormal];
            if (nil != title) {
                titleString = [[NSMutableAttributedString alloc] initWithString:title];
                [titleString addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:NSMakeRange(0, titleString.length)];
                [titleString addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, titleString.length)];
            }
        }
    }
    
    [self setAttributedTitle:titleString forState:state];
}

- (void)setEnableUnderline:(BOOL)enableUnderline
{
    if (enableUnderline) {
        NSString *title = [self titleForState:UIControlStateNormal];
        if (nil != title) {
            NSMutableAttributedString *titleString = [[NSMutableAttributedString alloc] initWithString:title];
            [titleString addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:NSMakeRange(0, titleString.length)];
            UIColor *color = [self titleColorForState:UIControlStateNormal];
            if (nil != color) {
                [titleString addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, titleString.length)];
            }
            [self setAttributedTitle:titleString forState:UIControlStateNormal];
        }
        
        [self setUnderlineAtrributedStringForState:UIControlStateHighlighted];
        [self setUnderlineAtrributedStringForState:UIControlStateSelected];
        [self setUnderlineAtrributedStringForState:UIControlStateDisabled];
        [self setUnderlineAtrributedStringForState:UIControlStateHighlighted | UIControlStateSelected];
    } else {
        [self setAttributedTitle:nil forState:UIControlStateNormal];
        [self setAttributedTitle:nil forState:UIControlStateHighlighted];
        [self setAttributedTitle:nil forState:UIControlStateSelected];
        [self setAttributedTitle:nil forState:UIControlStateDisabled];
        [self setAttributedTitle:nil forState:UIControlStateHighlighted | UIControlStateSelected];
    }
}


#pragma mark - alignmentRectInsets

- (UIEdgeInsets)alignmentRectInsets
{
    return self.btnExtra.alignmentRectInsets;
}

- (void)setAlignmentRectInsets:(UIEdgeInsets)alignmentRectInsets
{
    self.btnExtra.alignmentRectInsets = alignmentRectInsets;
}


#pragma mark - layoutStyle

- (void)addFrameObserver:(id)observer
{
    [self addObserver:observer forKeyPath:@"bounds" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:observer forKeyPath:@"frame" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:NULL];
}

- (void)removeFrameObserver:(id)observer
{
    [self removeObserver:observer forKeyPath:@"bounds" context:NULL];
    [self removeObserver:observer forKeyPath:@"frame" context:NULL];
}

- (TCButtonLayoutStyle)layoutStyle
{
    return self.btnExtra.layoutStyle;
}

- (void)setLayoutStyle:(TCButtonLayoutStyle)layoutStyle
{
    TCButtonExtra *btnExtra = self.btnExtra;
    if (btnExtra.layoutStyle == layoutStyle) {
        return;
    }
    
    btnExtra.layoutStyle = layoutStyle;
    
    if (!CGRectIsEmpty(self.frame)) {
        [self updateLayoutStyle];
    }
    
    if (layoutStyle != kTCButtonLayoutStyleDefault) {
        if (!btnExtra.isFrameObserved) {
            [self addFrameObserver:btnExtra];
            btnExtra.isFrameObserved = YES;
        }
    } else {
        if (btnExtra.isFrameObserved) {
            [self removeFrameObserver:btnExtra];
            btnExtra.isFrameObserved = NO;
            [self resetImageAndTitleEdges];
        }
    }
}

- (CGFloat)paddingBetweenTitleAndImage
{
    return self.btnExtra.paddingBetweenTitleAndImage;
}

- (void)setPaddingBetweenTitleAndImage:(CGFloat)paddingBetweenTitleAndImage
{
    self.btnExtra.paddingBetweenTitleAndImage = paddingBetweenTitleAndImage;
}


- (void)updateLayoutStyle
{
    switch (self.layoutStyle) {
        case kTCButtonLayoutStyleImageLeftTitleRight:
            [self imageAndTitleToFitHorizonal];
            break;
            
        case kTCButtonLayoutStyleImageRightTitleLeft:
            [self imageAndTitleToFitHorizonalReverse];
            break;
            
        case kTCButtonLayoutStyleImageTopTitleBottom:
            [self imageAndTitleToFitVerticalUp];
            break;
            
        case kTCButtonLayoutStyleImageBottomTitleTop:
            [self imageAndTitleToFitVerticalDown];
            break;
            
        default:
            break;
    }
}

- (void)noFrameKVOPerform:(dispatch_block_t)block
{
    if (nil == block) {
        return;
    }
    
    TCButtonExtra *btnExtra = self.btnExtra;
    BOOL observed = btnExtra.isFrameObserved;
    if (observed) {
        [self removeFrameObserver:btnExtra];
        btnExtra.isFrameObserved = NO;
    }
    
    block();
    dispatch_async(dispatch_get_main_queue(), ^{
        if (observed && !btnExtra.isFrameObserved) {
            [self addFrameObserver:btnExtra];
            btnExtra.isFrameObserved = YES;
        }
    });
}

- (void)imageAndTitleToFitVerticalUp
{
    if (nil != self.titleLabel && nil != self.imageView) {
        
        self.titleEdgeInsets = UIEdgeInsetsZero;
        self.imageEdgeInsets = UIEdgeInsetsZero;
        
        self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        
        [self.imageView sizeToFit];
        CGSize imageSize = self.imageView.frame.size;
        
        [self.titleLabel sizeToFit];
        self.titleEdgeInsets = UIEdgeInsetsMake(0, -imageSize.width, 0, 0);
        CGSize titleSize = self.titleLabel.frame.size;
        
        CGSize size = self.bounds.size;
        CGFloat pad = self.paddingBetweenTitleAndImage * 0.5f;
        CGFloat r = (titleSize.height + imageSize.height) * 0.5 - MIN(titleSize.height, imageSize.height);
        CGFloat border = self.layer.borderWidth;
        
        self.imageEdgeInsets = UIEdgeInsetsMake(-imageSize.height * 0.5 - pad + border + r, (size.width - imageSize.width) * 0.5, imageSize.height * 0.5 + pad - border - r, -(size.width - imageSize.width) * 0.5);
        self.titleEdgeInsets = UIEdgeInsetsMake(titleSize.height * 0.5 + pad + border + r, (size.width - titleSize.width) * 0.5 - imageSize.width, -titleSize.height * 0.5 - pad - border - r, 0);
        
        
//        self.backgroundColor = [UIColor yellowColor];
//        self.titleLabel.backgroundColor = [UIColor redColor];
        //            CGFloat expand = (titleSize.height + imageSize.height - size.height) * 0.5 + pad + border;
        //            CGRect bounds = self.bounds;
        //            bounds.size.height += expand * 2;
        //            self.bounds = bounds;
    }
}

- (void)imageAndTitleToFitVerticalDown
{
    if (nil != self.titleLabel && nil != self.imageView) {
        
        self.titleEdgeInsets = UIEdgeInsetsZero;
        self.imageEdgeInsets = UIEdgeInsetsZero;
        
        self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        
        [self.imageView sizeToFit];
        CGSize imageSize = self.imageView.frame.size;
        
        [self.titleLabel sizeToFit];
        self.titleEdgeInsets = UIEdgeInsetsMake(0, -imageSize.width, 0, 0);
        CGSize titleSize = self.titleLabel.frame.size;
        
        CGSize size = self.bounds.size;
        CGFloat pad = self.paddingBetweenTitleAndImage * 0.5f;
        CGFloat r = (titleSize.height + imageSize.height) * 0.5 - MIN(titleSize.height, imageSize.height);
        
        self.imageEdgeInsets = UIEdgeInsetsMake(imageSize.height * 0.5 + pad - r, (size.width - imageSize.width) * 0.5, -imageSize.height * 0.5 - pad + r, -titleSize.width);
        self.titleEdgeInsets = UIEdgeInsetsMake(-titleSize.height * 0.5 - pad - r, (size.width - titleSize.width) * 0.5 - imageSize.width, titleSize.height * 0.5 + pad + r, 0);
        
        //            CGFloat border = self.layer.borderWidth;
        //            CGFloat expand = (self.titleLabel.frame.size.height + self.imageView.frame.size.height - size.height) * 0.5 + pad + border;
        //            self.contentEdgeInsets = UIEdgeInsetsMake(expand, 0, expand, 0);
    }
}

- (void)imageAndTitleToFitHorizonalReverse
{
    if (nil != self.titleLabel && nil != self.imageView) {
        self.titleEdgeInsets = UIEdgeInsetsZero;
        self.imageEdgeInsets = UIEdgeInsetsZero;
        [self.imageView sizeToFit];
        [self.titleLabel sizeToFit];
        
        CGSize imageSize = self.imageView.frame.size;
        self.titleEdgeInsets = UIEdgeInsetsMake(0, -imageSize.width, 0, imageSize.width);
        CGSize titleSize = self.titleLabel.frame.size;
        self.imageEdgeInsets = UIEdgeInsetsMake(0, titleSize.width + self.paddingBetweenTitleAndImage, 0, -titleSize.width - self.paddingBetweenTitleAndImage);
        
        [self noFrameKVOPerform:^{
            CGFloat expand = self.paddingBetweenTitleAndImage * 0.5 + self.layer.borderWidth;
            self.contentEdgeInsets = UIEdgeInsetsMake(0, expand, 0, expand);
        }];
    }
}

- (void)imageAndTitleToFitHorizonal
{
    if (nil != self.titleLabel && nil != self.imageView) {
        
        self.titleEdgeInsets = UIEdgeInsetsZero;
        self.imageEdgeInsets = UIEdgeInsetsZero;
        [self.imageView sizeToFit];
        [self.titleLabel sizeToFit];
        
        CGFloat pad = self.paddingBetweenTitleAndImage * 0.5;
        CGFloat border = self.layer.borderWidth;
        self.titleEdgeInsets = UIEdgeInsetsMake(0, pad, 0, -pad);
        self.imageEdgeInsets = UIEdgeInsetsMake(0, -pad, 0, pad);
      
        [self noFrameKVOPerform:^{
            CGFloat expand = pad + border;
            self.contentEdgeInsets = UIEdgeInsetsMake(0, expand, 0, expand);
        }];
    }
}

- (void)resetImageAndTitleEdges
{
    self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleEdgeInsets = UIEdgeInsetsZero;
    self.imageEdgeInsets = UIEdgeInsetsZero;
    self.contentEdgeInsets = UIEdgeInsetsZero;
}


#pragma mark - backgroundColor

- (void)addStateObserver:(id)observer
{
    [self addObserver:observer forKeyPath:@"highlighted" options:NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:observer forKeyPath:@"selected" options:NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:observer forKeyPath:@"enabled" options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)removeStateObserver:(id)observer
{
    [self removeObserver:observer forKeyPath:@"highlighted" context:NULL];
    [self removeObserver:observer forKeyPath:@"selected" context:NULL];
    [self removeObserver:observer forKeyPath:@"enabled" context:NULL];
}

- (NSMutableDictionary *)innerBackgroundColorDic
{
    TCButtonExtra *btnExtra = self.btnExtra;
    if (nil == btnExtra.innerBackgroundColorDic) {
        btnExtra.innerBackgroundColorDic = [NSMutableDictionary dictionary];
        if (nil == btnExtra.borderColorDic) {
            [self addStateObserver:btnExtra];
        }
    }
    
    return btnExtra.innerBackgroundColorDic;
}

- (NSMutableDictionary *)borderColorDic
{
    TCButtonExtra *btnExtra = self.btnExtra;
    if (nil == btnExtra.borderColorDic) {
        btnExtra.borderColorDic = [NSMutableDictionary dictionary];
        if (nil == btnExtra.innerBackgroundColorDic) {
            [self addStateObserver:btnExtra];
        }
    }
    
    return btnExtra.borderColorDic;
}


- (UIColor *)backgroundColorForState:(UIControlState)state
{
    return self.innerBackgroundColorDic[@(state)];
}

- (void)setBackgroundColor:(UIColor *)color forState:(UIControlState)state
{
    if (nil == color) {
        [self.innerBackgroundColorDic removeObjectForKey:@(state)];
    }
    else {
        self.innerBackgroundColorDic[@(state)] = color;
        
        if ((UIControlStateNormal & state) == UIControlStateNormal) {
            if (nil == [self backgroundColorForState:state | UIControlStateHighlighted]) {
                self.innerBackgroundColorDic[@(state | UIControlStateHighlighted)] = color;
            }
            
            if (nil == [self backgroundColorForState:state | UIControlStateSelected]) {
                self.innerBackgroundColorDic[@(state | UIControlStateSelected)] = color;
            }
        }
    }
    
    if (state == self.state) {
        self.backgroundColor = color;
    }
}

- (UIColor *)borderColorForState:(UIControlState)state;
{
    return self.borderColorDic[@(state)];
}

- (void)setBorderColor:(UIColor *)color forState:(UIControlState)state
{
    if (nil == color) {
        [self.borderColorDic removeObjectForKey:@(state)];
    }
    else {
        self.borderColorDic[@(state)] = color;
        
        if ((UIControlStateNormal & state) == UIControlStateNormal) {
            if (nil == [self borderColorForState:state | UIControlStateHighlighted]) {
                self.borderColorDic[@(state | UIControlStateHighlighted)] = color;
            }
            
            if (nil == [self borderColorForState:state | UIControlStateSelected]) {
                self.borderColorDic[@(state | UIControlStateSelected)] = color;
            }
        }
    }
    
    if (state == self.state) {
        self.layer.borderColor = color.CGColor;
    }
}



@end
