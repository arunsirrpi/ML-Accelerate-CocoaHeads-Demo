//
//  GraphView.m
//
//  Created by Alexey Vlaskin on 3/02/2015.
//  Copyright (c) 2015 Alexey Vlaskin. All rights reserved.
//

#import "GraphView.h"
#import "AVVector.h"
#import "NSArray+Vector.h"
#import <Accelerate/Accelerate.h>

#define Radius 4
#define Border 10
@interface GraphView  ()

@property (nonatomic, strong) NSArray *points;
@property (nonatomic, strong) NSArray *extraPoints;
@property (nonatomic, strong) NSArray *linePoints;
@property (nonatomic, strong) NSArray *extraLinePoints;
@property (nonatomic, assign) BOOL isDots;
@property (nonatomic, assign) float maxx;
@property (nonatomic, assign) float maxy;
@property (nonatomic, assign) float minx;
@property (nonatomic, assign) float miny;

@end

@implementation GraphView

- (instancetype)init {
    self = [super init];
    if (self) {
        _points = nil;
        _extraPoints = nil;
        _isDots = NO;
        _lineColor = [UIColor yellowColor];
        _extraLineColor = [UIColor blueColor];
    }
    return self;
}

- (void)drawPoints:(NSArray *)points
             color:(UIColor *)color
           context:(CGContextRef)ctx
              rect:(CGRect)rect {
    CGMutablePathRef path = CGPathCreateMutable();
    if (points && points.count > 0) {
        CGPoint p = [(NSValue *)[points objectAtIndex:0] CGPointValue];
        CGPoint np = [self makeItNice:p rect:rect];
        CGPathMoveToPoint(path, nil, np.x,np.y);
        for (int i = 1; i < points.count; i++) {
            if (self.isDots) {
                CGPathMoveToPoint(path, nil, np.x+Radius,np.y);
                CGPathAddArc(path, nil, np.x,np.y, Radius, M_PI*2, 0, true);
                p = [(NSValue *)[points objectAtIndex:i] CGPointValue];
                np = [self makeItNice:p rect:rect];
            }
            else {
                p = [(NSValue *)[points objectAtIndex:i] CGPointValue];
                np = [self makeItNice:p rect:rect];
                CGPathAddLineToPoint(path, nil, np.x,np.y);
            }
        }
    }
    CGContextAddPath(ctx, path);
    CGContextSetLineWidth(ctx, 2);
    CGContextSetStrokeColorWithColor(ctx, color.CGColor);
    CGContextStrokePath(ctx);
    CGPathRelease(path);
}
- (CGPoint)makeItNice:(CGPoint)p rect:(CGRect)rect {
    return CGPointMake(Border + p.x*(rect.size.width-2*Border), Border + (rect.size.height-2*Border)*(1-p.y));
}
- (void)drawRect:(CGRect)rect {
    //drawing graph
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGContextSaveGState(ctx);
	CGContextSetFillColorWithColor(ctx, [UIColor blackColor].CGColor);
	CGContextFillRect(ctx, rect);
    if (self.points && self.points.count) {
        [self drawPoints:self.points color:[UIColor greenColor] context:ctx rect:rect];
    }
    if (self.extraPoints && self.extraPoints.count) {
        [self drawPoints:self.extraPoints color:[UIColor redColor] context:ctx rect:rect];
    }
    if (self.linePoints && self.linePoints.count>1) {
        [self drawLine:self.linePoints color:self.lineColor context:ctx rect:rect];
    }
    if (self.extraLinePoints && self.extraLinePoints.count>1) {
        [self drawLine:self.extraLinePoints color:self.extraLineColor context:ctx rect:rect];
    }
	//drawing coordinate bars
	float border = Border;
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathMoveToPoint(path, nil, border, border);
	CGPathAddLineToPoint(path, nil, border, rect.size.height);
	CGPathAddLineToPoint(path, nil, border, rect.size.height - border);
	CGPathAddLineToPoint(path, nil, 0, rect.size.height - border);
	CGPathAddLineToPoint(path, nil, rect.size.width - border, rect.size.height - border);
	CGContextAddPath(ctx, path);
	CGContextSetLineWidth(ctx, 1);
	CGContextSetStrokeColorWithColor(ctx, [UIColor redColor].CGColor);
	CGContextStrokePath(ctx);
	CGPathRelease(path);
	CGContextRestoreGState(ctx);
}

- (void)drawLine:(NSArray *)points
           color:(UIColor *)color
         context:(CGContextRef)ctx
            rect:(CGRect)rect {
    CGMutablePathRef path = CGPathCreateMutable();
    if (points && points.count > 1) {
        CGPoint p1 = [(NSValue *)[points objectAtIndex:0] CGPointValue];
        p1 = CGPointMake((p1.x-_minx)/(_maxx-_minx), (p1.y-_miny)/(_maxy-_miny));
        CGPoint np1 = [self makeItNice:p1 rect:rect];
        CGPathMoveToPoint(path,    nil,np1.x,np1.y);
        for (NSUInteger i=1;i<points.count;i++) {
            CGPoint p2 = [(NSValue *)[points objectAtIndex:i] CGPointValue];
            p2 = CGPointMake((p2.x-_minx)/(_maxx-_minx), (p2.y-_miny)/(_maxy-_miny));
            CGPoint np2 = [self makeItNice:p2 rect:rect];
            CGPathAddLineToPoint(path, nil,np2.x,np2.y);
        }
    }
    CGContextAddPath(ctx, path);
    CGContextSetLineWidth(ctx, 2);
    CGContextSetStrokeColorWithColor(ctx, color.CGColor);
    CGContextStrokePath(ctx);
    CGPathRelease(path);
}

- (void)setFloatScatterPlotData:(float *)yvalues
                        xvalues:(float *)xvalues
                         length:(NSUInteger)length {
    self.isDots = YES;
    vDSP_minv(yvalues, 1, &_miny, length);
    vDSP_maxv(yvalues, 1, &_maxy, length);
    vDSP_minv(xvalues, 1, &_minx, length);
    vDSP_maxv(xvalues, 1, &_maxx, length);
    __strong id *temp = (__strong id *)calloc(length, sizeof(id));
    dispatch_apply(length, dispatch_get_global_queue(0, 0), ^(size_t i) {
        float x = (xvalues[i] - _minx)/(_maxx - _minx);
        float y = (yvalues[i] - _miny)/(_maxy - _miny);
        temp[i] = [NSValue valueWithCGPoint:CGPointMake(x, y)];
    });
    self.points = [NSArray arrayWithObjects:temp count:length];
    free(temp);
    [self setNeedsDisplay];
}

- (void)setExtraLinePoints:(NSArray *)points {
    _extraLinePoints = [points copy];
    [self setNeedsDisplay];
}

- (void)setLinePoints:(NSArray *)points {
    _linePoints = [points copy];
    [self setNeedsDisplay];
}

- (void)setFloatData:(float *)values length:(NSUInteger)length {
    self.isDots = NO;
    self.points = [self floatDataToPoints:values length:length];
	[self setNeedsDisplay];
}

- (void)setExtraFloatData:(float *)values length:(NSUInteger)length {
    self.isDots = NO;
    self.extraPoints = [self floatDataToPoints:values length:length];
    [self setNeedsDisplay];
}

- (NSArray *)floatDataToPoints:(float *)values length:(NSUInteger)length {
    float min, max, var;
    vDSP_minv(values, 1, &min, length);
    vDSP_maxv(values, 1, &max, length);
    var = (max - min);
    float x = 1. / (float)(length-1);
    __strong id *temp = (__strong id *)calloc(length, sizeof(id));
    dispatch_apply(length, dispatch_get_global_queue(0, 0), ^(size_t i) {
        float y = (values[i]-min)/var;
        temp[i] = [NSValue valueWithCGPoint:CGPointMake(x * i, y)];
    });
    NSArray *res = [NSArray arrayWithObjects:temp count:length];
    free(temp);
    return res;
}

- (void)setData:(NSArray *)values {
    AVVector *v = [values toFloatVector];
    [self setFloatData:[v data] length:[v length]];
}

- (void)clear {
    self.isDots = NO;
    _points = nil;
    _extraPoints = nil;
    _linePoints = nil;
    [self setNeedsDisplay];
}

@end
