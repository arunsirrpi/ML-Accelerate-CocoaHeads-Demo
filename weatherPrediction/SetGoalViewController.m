//
//  SetGoalViewController.m
//  weatherPrediction
//
//  Created by Alexey Vlaskin on 6/05/2015.
//  Copyright (c) 2015 Alexey Vlaskin. All rights reserved.
//

#import "SetGoalViewController.h"
#import "NSArray+Util.h"
#import "NSArray+Vector.h"
#import "AVVector.h"
#import "AVMatrix.h"
#import "GraphView.h"
#import <Accelerate/Accelerate.h>

static NSString *const kSizeKey = @"Size";
static NSString *const kPriceKey = @"Price";


@interface SetGoalViewController () {
    double time[5];
}

@property (nonatomic, strong) AVVector *x;
@property (nonatomic, strong) AVVector *y;
@property (nonatomic, strong) GraphView *graphView;
@property (nonatomic, assign) NSUInteger state;
@property (nonatomic, assign) float minCost;

@end

@implementation SetGoalViewController

- (void)loadView {
    [super loadView];
    self.state = 0;
    self.graphView = [[GraphView alloc] init];
    [self.view addSubview:self.graphView];
    UIGestureRecognizer *r = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap:)];
    [self.view addGestureRecognizer:r];
    self.view.userInteractionEnabled = YES;
}

- (void)onTap:(UITapGestureRecognizer *)recognizer {
    self.state++;
    if (self.state==1) {
        [self showData];
    } else
    if (self.state>1 && self.state <= 15) {
        [self randomPick];
    } else if (self.state>15 && self.state<=115) {
        [self randomPick2];
    } else if (self.state==116) {
        NSLog(@"Time : %f %f %f %f %f",time[0],time[1],time[2],time[3],time[4]);
        NSLog(@"Dobe.");
    }
}

- (void)showData {
    AVVector *x = nil;
    AVVector *y = nil;
    [self generate:&x y:&y];
    [self.graphView clear];
    [self.graphView setFloatScatterPlotData:[y data] xvalues:[x data] length:[x length]];
    self.x = x;
    self.y = y;
}

- (void)randomPick {
    [self.graphView clear];
    [self.graphView setFloatScatterPlotData:[self.y data] xvalues:[self.x data] length:[self.x length]];
    float slope = 1 + (drand48()-0.5)*5;
    float intercept = ([self.y valueAt:[self.y length]/2] - slope*[self.x valueAt:[self.x length]/2]);
    NSLog(@"Line equation[%d] : Y = %f + %f * X",(int)self.state,intercept,slope);
    NSMutableArray *points= [NSMutableArray array];
    for (NSInteger i=-10;i<200;i++) {
        float x = i;
        CGPoint p = CGPointMake(x,  intercept + x*slope);
        [points addObject:[NSValue valueWithCGPoint:p]];
    }
    [self.graphView setLinePoints:[points copy]];
    self.minCost = 1000000;
    time[0]=time[1]=time[2]=time[3]=time[4]=0;
}

- (void)randomPick2 {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(100 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
        [self.graphView clear];
        [self.graphView setFloatScatterPlotData:[self.y data] xvalues:[self.x data] length:[self.x length]];
        float slope = 1 + (drand48()-0.5)*5;
        float intercept = ([self.y valueAt:[self.y length]/2] - slope*[self.x valueAt:[self.x length]/2]);
        //Cost function
        float cost,cost2,cost3,cost4,cost5;
        CFAbsoluteTime t1,t2,t3,t4,t5,t6;
        cost=cost2=cost3=cost4=0;
        
        for (int i =0;i<100;i++) {
            t1 = CFAbsoluteTimeGetCurrent();
            cost = [self considerCostFunctionWithIntercept:intercept slope:slope];
            t2 = CFAbsoluteTimeGetCurrent();
            cost2 = [self considerCostFunctionWithIntercept1:intercept slope:slope];
            t3 = CFAbsoluteTimeGetCurrent();
            cost3 = [self considerCostFunctionWithIntercept2:intercept slope:slope];
            t4 = CFAbsoluteTimeGetCurrent();
            cost4 = [self considerCostFunctionWithIntercept3:intercept slope:slope];
            t5 = CFAbsoluteTimeGetCurrent();
            cost5 = [self considerCostFunctionWithIntercept4:intercept slope:slope];
            t6 = CFAbsoluteTimeGetCurrent();
            time[0] += (t2-t1);
            time[1] += (t3-t2);
            time[2] += (t4-t3);
            time[3] += (t5-t4);
            time[4] += (t6-t5);
        }
        
//        if (cost!=cost2 || cost2!=cost3 || cost3!=cost4) {
//            NSLog(@"Error : const function should be same values");
//        }
        NSLog(@"Line[%d] : Y = %f + %f * X \t Cost : %f=%f",(int)self.state,intercept,slope,cost,cost2);
        NSMutableArray *points= [NSMutableArray array];
        for (NSInteger i=-10;i<200;i++) {
            float x = i;
            CGPoint p = CGPointMake(x,  intercept + x*slope);
            [points addObject:[NSValue valueWithCGPoint:p]];
        }
        [self.graphView setLinePoints:[points copy]];
        if (cost < self.minCost) {
            NSLog(@"^^^ ***Min Cost***");
            self.minCost = cost;
            [self.graphView setExtraLinePoints:[points copy]];
        }
        [self onTap:nil];
    });
}

- (float)considerCostFunctionWithIntercept:(float)B0 slope:(float)B1 {
    float sum = 0;
    NSUInteger l = self.x.length;
    for (NSUInteger i=0;i<l;i++) {
        float r = B0 + B1*self.x.data[i] - self.y.data[i];
        sum += r*r;
    }
    return sum;
}

- (float)considerCostFunctionWithIntercept1:(float)B0 slope:(float)B1 {
    NSUInteger l = self.x.length;
    float *tmp = calloc(sizeof(float),l*2);
    float *tmp2 = &tmp[l];
    float result = 0;
    vDSP_vmsb(&B1, 0, self.x.data, 1,self.y.data,1,tmp,1,l);// tmp  -> B1*x - y
    vDSP_vadd(&B0, 0, tmp, 1, tmp2, 1, l);                  // tmp2 -> B0 + tmp
    vDSP_dotpr(tmp2,1,tmp2,1,&result,l);    //tmp2 (dot) tmp2
    free(tmp);
    return result;
}

- (float)considerCostFunctionWithIntercept2:(float)B0 slope:(float)B1 {
    int l = (int)self.x.length;
    float result = 0;
    float *tmp = calloc(sizeof(float),l); vDSP_vfill(&B0,tmp,1,l);
    cblas_saxpy(l,-1,self.y.data,1,tmp,1);//tmp -> -1*y + B0
    cblas_saxpy(l,B1,self.x.data,1,tmp,1);//tmp -> B1*x + tmp
    result = cblas_sdot((const int)l,tmp,1,tmp,1); //tmp (dot) tmp
    free(tmp);
    return result;
}

- (float)considerCostFunctionWithIntercept3:(float)B0 slope:(float)B1 {
    int l = (int)self.x.length;
    float result = 0;
    float *tmp = calloc(sizeof(float),l); vDSP_vfill(&B0,tmp,1,l);
    la_object_t vB0 = la_vector_from_float_buffer(tmp, l, 1, LA_DEFAULT_ATTRIBUTES);
    la_object_t vx =  la_vector_from_float_buffer(self.x.data, l, 1, LA_DEFAULT_ATTRIBUTES);
    la_object_t vy =  la_vector_from_float_buffer(self.y.data, l, 1, LA_DEFAULT_ATTRIBUTES);
    la_object_t resV = la_sum(la_sum(vB0, la_scale_with_float(vx,B1)), la_scale_with_float(vy,-1));
    la_object_t resO = la_inner_product (resV , resV);
    la_vector_to_float_buffer(&result,0,resO);
    free(tmp);
    return result;
}

- (float)considerCostFunctionWithIntercept4:(float)intercept slope:(float)slope {
    NSError *error = nil;
    AVVector *thetta = [[AVVector alloc] initWithLength:2];
    AVVector *ones = [[AVVector alloc] initOneWithLength:[self.x length]];
    [thetta setValue:intercept atIndex:0];
    [thetta setValue:slope atIndex:1];
    AVMatrix * X = [[AVMatrix alloc] initWithRows:[self.x length] cols:2];
    [X setColumnWithVector:ones columnIndex:0];
    [X setColumnWithVector:self.x columnIndex:1];
    AVVector *res = [AVMatrix mulMatrix:X byVector:thetta error:&error];
    [res substractVector:self.y];
    [res power2];
    return [res sumElements];
}

- (NSArray *)readFromCSV:(NSUInteger)index {
    NSError *outError = nil;
    NSString *pathToFile = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"lrdata%d",(int)index] ofType:@"csv"];
    NSString *fileString = [NSString stringWithContentsOfFile:pathToFile encoding:NSUTF8StringEncoding error:&outError];
    if (!fileString) {
        NSLog(@"Error reading file.");
    }
    NSArray *allLines = [fileString componentsSeparatedByString:@"\n"];
    NSArray *data = [allLines mapArrayWithBlock:^id(id object, NSUInteger idx) {
        return [[self class] processReadLine:object];
    }];
    return data;
}
/*
 
 Suppose in some area price and size of the area are looking like this.
 
 */
+ (NSDictionary *)processReadLine:(NSString *)lineStr {
    NSArray *comps = [lineStr componentsSeparatedByString:@","];
    if (comps.count > 1) {
        NSDictionary *d = @{ kSizeKey : @([comps[0] floatValue]),
                             kPriceKey     : @([comps[1] floatValue]) };
        return d;
    }
    return nil;
}

- (void)generate:(AVVector **)x y:(AVVector **)y {
    NSUInteger max = 15;
    *y = [[AVVector alloc] initWithLength:max];
    *x = [[AVVector alloc] initWithLength:max];
    
    for (NSUInteger i=0;i<max;i++) {
        float xv = 5 + i*5;
        float yv = 2*3.5*3.5+2.367*xv+(drand48()-0.5)*4.76;
        [*x setValue:xv atIndex:i];
        [*y setValue:yv atIndex:i];
        NSLog(@"%f,%f",xv,yv);
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.graphView.frame = CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.width);
}

+ (UIColor *)awesomeBank50PercentBlack {
    return [UIColor colorWithRed:143/255. green:143/255. blue:143/255. alpha:1];
}

+ (UIColor *)awesomeBank55PercentBlack {
    return [UIColor colorWithRed:154/255. green:154/255. blue:166/255. alpha:1];
}

+ (UIColor *)awesomeBank60PercentBlack {
    return [UIColor colorWithRed:166/255. green:166/255. blue:166/255. alpha:1];
}

+ (UIColor *)awesomeBankPercentBlack:(float)percent {
    return nil;//give me magic!!!
}


@end
