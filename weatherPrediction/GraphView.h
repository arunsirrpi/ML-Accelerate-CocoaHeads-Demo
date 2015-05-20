//
//  GraphView.h
//
//  Created by Alexey Vlaskin on 3/02/2015.
//  Copyright (c) 2015 Alexey Vlaskin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GraphView : UIView

@property (nonatomic, assign) double timeOfDrawing;
@property (nonatomic, assign) NSUInteger numberOfDraws;
@property (nonatomic, strong) UIColor *lineColor;
@property (nonatomic, strong) UIColor *extraLineColor;

- (void)setLinePoints:(NSArray *)points;
- (void)setExtraLinePoints:(NSArray *)points;

- (void)setFloatScatterPlotData:(float *)yvalues
                        xvalues:(float *)xvalues
                         length:(NSUInteger)length;
- (void)setExtraFloatData:(float *)values
                   length:(NSUInteger)length;
- (void)setFloatData:(float *)data
              length:(NSUInteger)length;
- (void)setData:(NSArray *)values;
- (void)clear;

@end
