//
//  ViewController.m
//  weatherPrediction
//
//  Created by Alexey Vlaskin on 22/04/2015.
//  Copyright (c) 2015 Alexey Vlaskin. All rights reserved.
//

#import "ViewController.h"
#import "NSArray+Util.h"
#import "NSArray+Vector.h"
#import "AVVector.h"
#import "AVMatrix.h"
#import "GraphView.h"
#import <Accelerate/Accelerate.h>
#import "AVNeuralNetwork.h"
#import "AVNeuralNetwork+Tests.h"

static NSString *const kPopulationKey = @"Pop";
static NSString *const kProfitKey = @"Prof";


@interface ViewController ()
@property (nonatomic, strong) NSArray *data;
@property (nonatomic, strong) GraphView *graphView;
@property (nonatomic, strong) UISlider *slider;
@property (nonatomic, strong) UILabel *sliderLabel;
@property (nonatomic, assign) float sliderValue;
@property (nonatomic, assign) NSUInteger state;
@end

@implementation ViewController

- (void)loadView {
    [super loadView];
    self.state = 0;
    self.graphView = [[GraphView alloc] init];
    [self.view addSubview:self.graphView];
    UIGestureRecognizer *r = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap:)];
    [self.graphView addGestureRecognizer:r];
    self.graphView.userInteractionEnabled = YES;
    self.view.userInteractionEnabled = YES;
    [self mySlider];
}

-(void)fillTest {
    int m = 100;
    float v = 1.f;
    double time[2] = {0,0};
    float *f0 = calloc(sizeof(float), m);
    float *f1 = calloc(sizeof(float), m);
    for (int j = 0; j<10000;j++) {
    CFAbsoluteTime t1 = CFAbsoluteTimeGetCurrent();
        for (int i=0;i<m;i++) {
            f0[i] = v;
        }
        CFAbsoluteTime t2 = CFAbsoluteTimeGetCurrent();
        vDSP_vfill(&v,f1,1, m);
        CFAbsoluteTime t3 = CFAbsoluteTimeGetCurrent();
        time[0] += t2 - t1;
        time[1] += t3 - t2;
    }
    NSLog(@"Fill Time %f %f",time[0],time[1]);
}

-(void)mySlider
{
    if (!self.slider) {
        self.slider = [[UISlider alloc] initWithFrame:CGRectZero];
        [self.slider addTarget:self action:@selector(sliderAction:) forControlEvents:UIControlEventValueChanged];
        [self.slider setBackgroundColor:[UIColor clearColor]];
        self.slider.minimumValue = 0.0;
        self.slider.maximumValue = 50.0;
        self.slider.continuous = YES;
        self.slider.value = 0.0;
        [self.view addSubview:self.slider];
        self.slider.hidden = YES;
        self.sliderValue = 0;
        
        self.sliderLabel = [[UILabel alloc] init];
        self.sliderLabel.textColor = [UIColor blueColor];
        self.sliderLabel.backgroundColor = [UIColor clearColor];
        [self.view addSubview:self.sliderLabel];
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.graphView.frame = CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.width);
    self.sliderLabel.frame = CGRectMake(self.view.frame.size.width/2 - 75, 20 + CGRectGetMaxY(self.graphView.frame), 150, 40);
    self.slider.frame = CGRectMake(30, 20 + CGRectGetMaxY(self.sliderLabel.frame), self.view.frame.size.width-60, 20);
}

-(void)sliderAction:(id)sender
{
    UISlider *slider = (UISlider*)sender;
    self.sliderValue = slider.value;
    self.sliderLabel.text = [NSString stringWithFormat:@"Value : %f",self.sliderValue];
    _state-=1;
    [self onTap:nil];
}

- (void)onTap:(UITapGestureRecognizer *)recognizer {
    self.state++;
    if (self.state==1) {
        self.data = [self readFromCSV:1];
        [self showData1];
    } else
        if (self.state==2) {
        [self solveLinearRegression1];
    }  else
    if (self.state==3) {
        self.data = [self readFromCSV:2];
        [self showData2];
    } else
    if (self.state==4) {
        [self solveLinearRegression21];
    } else if (self.state==5) {
        [self solveLinearRegression22];
    } else if (self.state == 6) {
        [self solveLinearRegression3];
        //[self solveUsingNeuralNetwork];
    } else if (self.state == 7) {
        [self solveLinearRegression31:1];
        self.slider.hidden = NO;
    } else if (self.state == 8) {
        [self solveLinearRegression31:2];
    } else if (self.state == 9) {
        [self solveLinearRegression31:3];
    } else if (self.state == 10) {
        [self solveLinearRegression31:4];
    } else if (self.state == 12) {
        [self solveLinearRegression4];
    } else if (self.state == 13) {
        [self solveLinearRegression41:4];
    }
}

-(void)showData1 {
    NSArray *population = [self.data mapArrayWithBlock:^id(NSDictionary* object, NSUInteger idx) {
        return @([[object objectForKey:kPopulationKey] floatValue]);
    }];
    NSArray *profit = [self.data mapArrayWithBlock:^id(NSDictionary* object, NSUInteger idx) {
        return @([[object objectForKey:kProfitKey] floatValue]);
    }];
    AVVector *pop = [population toFloatVector];
    AVVector *prof = [profit toFloatVector];
    NSLog(@"Correlation : %f",[AVVector correlation:pop with:prof]);
    [self.graphView setFloatScatterPlotData:[prof data] xvalues:[pop data] length:[pop length]];
    NSLog(@"Done");
}

-(void)showData2 {
    NSArray *time = [self.data mapArrayWithBlock:^id(NSDictionary* object, NSUInteger idx) {
        return @([[object objectForKey:kPopulationKey] floatValue]);
    }];
    NSArray *height = [self.data mapArrayWithBlock:^id(NSDictionary* object, NSUInteger idx) {
        return @([[object objectForKey:kProfitKey] floatValue]);
    }];
    AVVector *x = [time toFloatVector];
    AVVector *y = [height toFloatVector];
    NSLog(@"Correlation : %f",[AVVector correlation:x with:y]);
    [self.graphView setFloatScatterPlotData:[y data] xvalues:[x data] length:[x length]];
    NSLog(@"Done");
}

-(void)solveLinearRegression1 {
    NSError *err = nil;
    NSArray *population = [self.data mapArrayWithBlock:^id(NSDictionary* object, NSUInteger idx) {
        return @([[object objectForKey:kPopulationKey] floatValue]);
    }];
    NSArray *profit = [self.data mapArrayWithBlock:^id(NSDictionary* object, NSUInteger idx) {
        return @([[object objectForKey:kProfitKey] floatValue]);
    }];
    AVVector *pop = [population toFloatVector];
    AVVector *prof = [profit toFloatVector];
    [self.graphView setFloatScatterPlotData:[prof data] xvalues:[pop data] length:[pop length]];
    AVMatrix *X = [[AVMatrix alloc] initWithRows:pop.length cols:2];
    [X setFirstColumnToOne];
    [X setColumnWithVector:pop columnIndex:1];
    AVMatrix *X_t = [AVMatrix transposeMatrix:X];
    AVMatrix *ai = [AVMatrix mulMatrix:X_t by:X error:&err];
    CFAbsoluteTime t1 = CFAbsoluteTimeGetCurrent();
    AVMatrix *inversedA1 = [AVMatrix inverseSquareMatrix:ai];
    CFAbsoluteTime t2 = CFAbsoluteTimeGetCurrent();
    AVMatrix *inversedA2 = [AVMatrix inverse2SquareMatrix:ai];
    CFAbsoluteTime t3 = CFAbsoluteTimeGetCurrent();
    AVMatrix *inversedA3 = [AVMatrix inverse3SquareMatrix:ai];
    CFAbsoluteTime t4 = CFAbsoluteTimeGetCurrent();
    NSLog(@"Inverse 1: %f Inverse 2: %f Inverse 3: %f",(t2-t1),(t3-t2),(t4-t3));
    
    AVMatrix *xxx = [AVMatrix mulMatrix:inversedA1 by:X_t error:&err];
    AVVector *thetta = [AVMatrix mulMatrix:xxx byVector:prof error:&err];
    CGPoint p1 = CGPointMake(0,  thetta.data[0] );
    CGPoint p2 = CGPointMake(100,  thetta.data[0] + 100*thetta.data[1]);
    [self.graphView setLinePoints:@[[NSValue valueWithCGPoint:p1],[NSValue valueWithCGPoint:p2]]];
    NSLog(@"Thetta: %@",thetta);
    NSLog(@"Done");
}

-(void)solveLinearRegression21 {
    NSError *err = nil;
    NSArray *time = [self.data mapArrayWithBlock:^id(NSDictionary* object, NSUInteger idx) {
        return @([[object objectForKey:kPopulationKey] floatValue]);
    }];
    NSArray *height = [self.data mapArrayWithBlock:^id(NSDictionary* object, NSUInteger idx) {
        return @([[object objectForKey:kProfitKey] floatValue]);
    }];
    AVVector *x = [time toFloatVector];
    AVVector *y = [height toFloatVector];
    NSLog(@"Correlation : %f",[AVVector correlation:x with:y]);
    [self.graphView setFloatScatterPlotData:[y data] xvalues:[x data] length:[x length]];
    
    AVMatrix *X = [[AVMatrix alloc] initWithRows:x.length cols:2];
    [X setFirstColumnToOne];
    [X setColumnWithVector:x columnIndex:1];
    
    AVMatrix *X_t = [AVMatrix transposeMatrix:X];
    AVMatrix *XX = [AVMatrix mulMatrix:X_t by:X error:&err];
    AVMatrix *inversedA1 = [AVMatrix inverseSquareMatrix:XX];
    AVMatrix *XXX = [AVMatrix mulMatrix:inversedA1 by:X_t error:&err];
    AVVector *thetta = [AVMatrix mulMatrix:XXX byVector:y error:&err];
    NSLog(@"Thetta: %@",thetta);
    
    NSMutableArray *points= [NSMutableArray array];
    CGPoint p1 = CGPointMake(0,  thetta.data[0]);
    [points addObject:[NSValue valueWithCGPoint:p1]];
    for (NSUInteger i=1;i<50;i++) {
        float x = i*0.2;
        CGPoint p2 = CGPointMake(x,  thetta.data[0] + x*thetta.data[1]);
        [points addObject:[NSValue valueWithCGPoint:p2]];
    }
    [self.graphView setLinePoints:[points copy]];
}

-(void)solveLinearRegression22 {
    NSError *err = nil;
    NSArray *time = [self.data mapArrayWithBlock:^id(NSDictionary* object, NSUInteger idx) {
        return @([[object objectForKey:kPopulationKey] floatValue]);
    }];
    NSArray *height = [self.data mapArrayWithBlock:^id(NSDictionary* object, NSUInteger idx) {
        return @([[object objectForKey:kProfitKey] floatValue]);
    }];
    AVVector *x = [time toFloatVector];
    AVVector *x2 = [x vectorOfPower2];
    AVVector *y = [height toFloatVector];
    NSLog(@"Correlation : %f",[AVVector correlation:x with:y]);
    [self.graphView setFloatScatterPlotData:[y data] xvalues:[x data] length:[x length]];
    
    AVMatrix *X = [[AVMatrix alloc] initWithRows:x.length cols:3];
    [X setFirstColumnToOne];
    [X setColumnWithVector:x columnIndex:1];
    [X setColumnWithVector:x2 columnIndex:2];
    
    AVMatrix *X_t = [AVMatrix transposeMatrix:X];
    AVMatrix *XX = [AVMatrix mulMatrix:X_t by:X error:&err];
    CFAbsoluteTime t1 = CFAbsoluteTimeGetCurrent();
    AVMatrix *inversedA1 = [AVMatrix inverseSquareMatrix:XX];
    CFAbsoluteTime t2 = CFAbsoluteTimeGetCurrent();
    AVMatrix *inversedA2 = [AVMatrix inverse2SquareMatrix:XX];
    CFAbsoluteTime t3 = CFAbsoluteTimeGetCurrent();
    AVMatrix *inversedA3 = [AVMatrix inverse3SquareMatrix:XX];
    CFAbsoluteTime t4 = CFAbsoluteTimeGetCurrent();
    NSLog(@"Inverse 1: %f Inverse 2: %f Inverse 3: %f",(t2-t1),(t3-t2),(t4-t3));
    AVMatrix *XXX = [AVMatrix mulMatrix:inversedA1 by:X_t error:&err];
    AVVector *thetta = [AVMatrix mulMatrix:XXX byVector:y error:&err];
    NSLog(@"Thetta: %@",thetta);
    
    NSMutableArray *points = [NSMutableArray array];
    CGPoint p1 = CGPointMake(0,  thetta.data[0]);
    [points addObject:[NSValue valueWithCGPoint:p1]];
    for (NSUInteger i=1;i<50;i++) {
        float x = i*0.2;
        CGPoint p2 = CGPointMake(x,  thetta.data[0] + x*thetta.data[1] + x*x*thetta.data[2]);
        [points addObject:[NSValue valueWithCGPoint:p2]];
        NSLog(@"Point: %@",NSStringFromCGPoint(p2));
    }
    [self.graphView setLinePoints:[points copy]];
    
    NSLog(@"Done");
}

-(AVVector *)solvePolynomRegressionWithFeature:(AVVector *)x
                                             y:(AVVector *)y
                                        degree:(NSUInteger)d
                       regularisationParamater:(float)lyambda
{
    NSError *err = nil;
    AVMatrix *X = [[AVMatrix alloc] initWithRows:x.length cols:d+1];
    [X setFirstColumnToOne];
    [X setColumnWithVector:x columnIndex:1];
    for (NSUInteger i=2;i<=d;i++) {
        AVVector *v = [x vectorOfPower:i];//vvpowsf(res.data, &power, _vector_values, &l);
        [X setColumnWithVector:v columnIndex:i];
    }
    AVMatrix *X_t = [AVMatrix transposeMatrix:X];
    AVMatrix *XX = [AVMatrix mulMatrix:X_t by:X error:&err];
    
    if (lyambda > 0.001) {
        //regularisation part :
        AVMatrix *E = [AVMatrix identityMatrixOfSize:XX.rows];
        E.data[0] = 0;
        [E multiplyByScalar:lyambda];
        XX = [AVMatrix sumMatrix:XX with:E error:&err];
    }
    AVMatrix *inversedXX = [AVMatrix inverseSquareMatrix:XX];
    AVMatrix *XXX = [AVMatrix mulMatrix:inversedXX by:X_t error:&err];
    AVVector *thetta = [AVMatrix mulMatrix:XXX byVector:y error:&err];
    return thetta;
}
//temporary postponed
- (float)computeCostFunctionForThetta:(AVVector *)thetta
                              feature:(AVVector *)x
                                    y:(AVVector *)y
                               degree:(NSUInteger)d
              regularisationParamater:(float)lyambda
{
    AVMatrix *X = [[AVMatrix alloc] initWithRows:x.length cols:d+1];
    [X setFirstColumnToOne];
    [X setColumnWithVector:x columnIndex:1];
    for (NSUInteger i=2;i<=d;i++) {
        AVVector *v = [x vectorOfPower:i];//vvpowsf(res.data, &power, _vector_values, &l);
        [X setColumnWithVector:v columnIndex:i];
    }
    return 0;
}

-(AVVector *)solvePolynomialRegressionWithFeature:(AVVector *)x
                                             y:(AVVector *)y
                                        degree:(NSUInteger)d
                       regularisationParamater:(float)lyambda
{
    NSError *err = nil;
    AVMatrix *X = [[AVMatrix alloc] initWithRows:x.length cols:d+1];
    [X setFirstColumnToOne];
    [X setColumnWithVector:x columnIndex:1];
    for (NSUInteger i=2;i<=d;i++) {
        AVVector *v = [x vectorOfPower:i];//vvpowsf(res.data, &power, _vector_values, &l);
        [X setColumnWithVector:v columnIndex:i];
    }
    AVMatrix *X_t = [AVMatrix transposeMatrix:X];
    AVMatrix *XX = [AVMatrix mulMatrix:X_t by:X error:&err];
    if (lyambda > 0.001) {
        //regularisation part :
        AVMatrix *E = [AVMatrix identityMatrixOfSize:XX.rows];
        E.data[0] = 0;
        [E multiplyByScalar:lyambda];
        XX = [AVMatrix sumMatrix:XX with:E error:&err];
    }
    double time[4] = {0,0,0,0};
    AVVector *thetta = nil;
    AVVector *thetta2 = nil;
    AVVector *thetta3 = nil;

    for (int i=0;i<1000;i++) {
        CFAbsoluteTime t1 = CFAbsoluteTimeGetCurrent();
        AVMatrix *inversedXX = [AVMatrix inverse2SquareMatrix:XX];
        AVMatrix *XXX = [AVMatrix mulMatrix:inversedXX by:X_t error:&err];
        thetta = [AVMatrix mulMatrix:XXX byVector:y error:&err];
        CFAbsoluteTime t2 = CFAbsoluteTimeGetCurrent();
        AVMatrix *inversedXX2 = [AVMatrix inverseSquareMatrix:XX];
        XXX = [AVMatrix mulMatrix:inversedXX2 by:X_t error:&err];
        thetta2 = [AVMatrix mulMatrix:XXX byVector:y error:&err];
        CFAbsoluteTime t3 = CFAbsoluteTimeGetCurrent();
        la_object_t la_A = la_matrix_from_float_buffer(XX.data, XX.rows, XX.cols, XX.cols, LA_NO_HINT, LA_DEFAULT_ATTRIBUTES);
        la_object_t la_Xt = la_matrix_from_float_buffer(X_t.data, X_t.rows, X_t.cols, X_t.cols, LA_NO_HINT, LA_DEFAULT_ATTRIBUTES);
        la_object_t la_y = la_vector_from_float_buffer(y.data, y.length, 1, LA_DEFAULT_ATTRIBUTES);
        la_object_t la_b = la_matrix_product(la_Xt, la_y);
        la_object_t la_x = la_solve(la_A, la_b);
        
        float *res = calloc(sizeof(float), y.length);
        if (la_vector_to_float_buffer(res, 1, la_x) != LA_SUCCESS) {
            NSLog(@"Failed");
            return nil;
        }
        thetta2 = [[AVVector alloc] initWithLength:y.length dataRetained:res];
        CFAbsoluteTime t4 = CFAbsoluteTimeGetCurrent();
        AVMatrix *inversedXX3 = [AVMatrix inverse3SquareMatrix:XX];
        XXX = [AVMatrix mulMatrix:inversedXX3 by:X_t error:&err];
        thetta3 = [AVMatrix mulMatrix:XXX byVector:y error:&err];
        CFAbsoluteTime t5 = CFAbsoluteTimeGetCurrent();
        time[0] += t2 - t1;
        time[1] += t3 - t2;
        time[2] += t4 - t3;
        time[3] += t5 - t4;
    }
    NSLog(@"%@ %@",thetta,thetta2);
    NSLog(@"Time1 %f Time2 %f Time3 %f Time4 %f",time[0],time[1],time[2],time[3]);
    return thetta;
}

-(void)solveLinearRegression3 {
    AVVector *x = nil;
    AVVector *y = nil;
    [self generateX:&x y:&y start:-2 end:2 numberOfExamples:50 degree:3];
    [self.graphView clear];
    [self.graphView setFloatScatterPlotData:[y data] xvalues:[x data] length:[x length]];
}

- (void)solveLinearRegression31:(NSUInteger)degree {
    AVVector *x = nil;
    AVVector *y = nil;
    NSUInteger m = 70;
    [self generateX:&x y:&y start:-2.1 end:4 numberOfExamples:50 degree:degree];
    AVVector *thetta = [self solvePolynomRegressionWithFeature:x
                                                             y:y
                                                        degree:degree
                                       regularisationParamater:self.sliderValue];
    NSMutableArray *points = [NSMutableArray array];
    for (NSUInteger i=1;i<m;i++) {
        float x = -2.1 + 6.0*i/m;
        float xv = x;
        float y = thetta.data[0];
        for (NSUInteger j=1;j<=degree;j++) {
            y += xv*thetta.data[j];
            xv *= x;
        }
        CGPoint p2 = CGPointMake(x, y);
        [points addObject:[NSValue valueWithCGPoint:p2]];
        NSLog(@"Point: %@",NSStringFromCGPoint(p2));
    }
    [self.graphView setLinePoints:[points copy]];
    NSLog(@"Done.");
}

- (void)solveLinearRegression41:(NSUInteger)degree {
    AVVector *x = nil;
    AVVector *y = nil;
    NSUInteger m = 70;
    [self generateX:&x y:&y start:-1.5 end:2.3 numberOfExamples:50 degree:degree];
    AVVector *thetta = [self solvePolynomialRegressionWithFeature:x
                                                                y:y
                                                           degree:degree
                                          regularisationParamater:self.sliderValue];
    NSMutableArray *points = [NSMutableArray array];
    for (NSUInteger i=1;i<m;i++) {
        float x = -1.5 + 4.0*i/m;
        float xv = x;
        float y = thetta.data[0];
        for (NSUInteger j=1;j<=degree;j++) {
            y += xv*thetta.data[j];
            xv *= x;
        }
        CGPoint p2 = CGPointMake(x, y);
        [points addObject:[NSValue valueWithCGPoint:p2]];
        NSLog(@"Point: %@",NSStringFromCGPoint(p2));
    }
    [self.graphView setLinePoints:[points copy]];
    NSLog(@"Done.");
}

-(void)solveLinearRegression4 {
    AVVector *x = nil;
    AVVector *y = nil;
    [self generateX:&x y:&y start:-5 end:5 numberOfExamples:50 degree:4];
    [self.graphView clear];
    [self.graphView setFloatScatterPlotData:[y data] xvalues:[x data] length:[x length]];
}

- (void)solveUsingNeuralNetwork {
    NSArray *time = [self.data mapArrayWithBlock:^id(NSDictionary* object, NSUInteger idx) {
        return @([[object objectForKey:kPopulationKey] floatValue]);
    }];
    NSArray *height = [self.data mapArrayWithBlock:^id(NSDictionary* object, NSUInteger idx) {
        return @([[object objectForKey:kProfitKey] floatValue]);
    }];
    
    AVVector *x = [time toFloatVector];
    AVVector *y = [height toFloatVector];
    float meanX = [x mean];
    float minX= [x findMin];
    float maxX= [x findMax];
    
    float minY= [y findMin];
    float maxY= [y findMax];
    
    [self.graphView clear];
    [self.graphView setFloatScatterPlotData:[y data] xvalues:[x data] length:[x length]];
    
    [x meanNormalise];
    [y normalise];
    
    NSUInteger pol = 2;
    float layersFloats[] = { pol ,2, 10 , 1 }; //magic numbers, play with them
    AVVector *layers = [[AVVector alloc] initWithLength:sizeof(layersFloats)/sizeof(float) data:layersFloats];
    AVNeuralNetwork *net = [[AVNeuralNetwork alloc] initWithLayers:layers];
    
    
    AVMatrix *inputsM = [[AVMatrix alloc] initWithRows:pol cols:x.length];
    for (NSUInteger i=0; i<x.length; i++) {
        AVVector *v = [[AVVector alloc] initWithLength:pol];
        float x_v = [x valueAt:i];
        float x_s = [x valueAt:i];
        for (NSUInteger j=0;j<pol;j++) {
            [v setValue:x_v atIndex:j];
            x_v = x_v * x_s;
        }
        [inputsM setColumnWithVector:v columnIndex:i];
    }
    AVMatrix *outputsM = [[AVMatrix alloc] initWithRows:1 cols:x.length];
    for (NSUInteger i=0; i<x.length; i++) {
        [outputsM setValue:i y:0 value:[y valueAt:i]];
    }
    NSError *error = nil;
    float before = 1000;
    float after = 100;
    int i = 0;
    BOOL keepGoing = YES;
    float l = 0.01;
    float stopTeach = 0.00001;
    do
    {
        before = [net computeCostFunction:inputsM outputs:outputsM lyambda:l error:&error];
        for (int j=0;j<x.length;j++) {
            AVVector *input = [inputsM columnToVector:j];
            AVVector *expectedOutput = [outputsM columnToVector:j];
            [net computeWithInput:input error:&error];
            [net computeBackPropagationForExpectedOutput:expectedOutput
                                                        error:&error];
            [net computeDeltaThettas:&error];
            [net cleanForwardAndBack];
        }
        [net changeDeltasWithLyambda:l trainingSet:x.length];
        if (error)
        {
            return;
        }
        after = [net computeCostFunction:inputsM outputs:outputsM lyambda:l error:&error];
        NSLog(@"Cost function before:%f after:%f Lyambda: %f",before,after,l);
        i++;
        if (fabsf(after)>stopTeach) {
            if (fabsf(before) > fabsf(after)) {
                //keep going. all good.
            } else {
                l=l/2;
                if (l < 0.00001) {
                    keepGoing = NO;//comment
                }
            }
        } else {
            keepGoing = NO;
        }
    }while(keepGoing);
    
    NSLog(@"Network is taught in %d itterations",i);

    
    AVVector *input = [[AVVector alloc] initWithLength:pol];
    NSMutableArray *points = [NSMutableArray array];
    for (NSUInteger i=0;i<50;i++) {
        float x = i*0.2;
        [input setValue:(x - meanX)/(maxX-minX) atIndex:0];
        [input setValue:(x - meanX)/(maxX-minX)*(x - meanX)/(maxX-minX) atIndex:1];
        //[input setValue:(x - meanX)/(maxX-minX)*(x - meanX)/(maxX-minX)*(x - meanX)/(maxX-minX) atIndex:1];
        
        AVVector *output = [net computeWithInput:input error:&error];
        NSLog(@"Input :%f %f Out: %f",[input valueAt:0],[input valueAt:1],[output valueAt:0]);
        float res = [output valueAt:0]*(maxY-minY) + minY;
        CGPoint p2 = CGPointMake(x, res);
        [points addObject:[NSValue valueWithCGPoint:p2]];
        NSLog(@"Point: %@",NSStringFromCGPoint(p2));
    }
    [self.graphView setLinePoints:[points copy]];
    
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
 Suppose you are the CEO of a restaurant franchise and are considering different cities for opening a new outlet. The chain already has trucks in various cities and you have data for profits and populations from the cities. You would like to use this data to help you select which city to expand to next.
 */
+ (NSDictionary *)processReadLine:(NSString *)lineStr {
    NSArray *comps = [lineStr componentsSeparatedByString:@","];
    if (comps.count > 1) {
        NSDictionary *d = @{ kPopulationKey : @([comps[0] floatValue]),
                             kProfitKey     : @([comps[1] floatValue]) };
        return d;
    }
    return nil;
}
- (void)generateX:(AVVector **)x
                y:(AVVector **)y
            start:(float)s
              end:(float)e
 numberOfExamples:(NSUInteger)max
           degree:(NSUInteger)d
{
    *y = [[AVVector alloc] initWithLength:max];
    *x = [[AVVector alloc] initWithLength:max];
    AVVector *dd = [[AVVector alloc] initWithLength:d];
    

    dd.data[0] = - 0.3;
    for (NSUInteger j=1;j<d;j++) {
        float r = (drand48()-0.5)*17;
        [dd setValue:r atIndex:j];
        NSLog(@"%f",r);
    }
    if (d == 3) {
        dd.data[0] = -0.075;
        dd.data[1] = -1;
        dd.data[2] = 0.3;
        s = -2.1;
        e = 4;
    }
    if (d == 4) {
        dd.data[1] = -4.5;
        dd.data[2] = -1.3;
        dd.data[3] = 2;
        s = -1.5;
        e = 2.3;
    }
    for (NSUInteger i=0;i<max;i++) {
        float xv = s + i*(e-s)/(float)max;
        float mxv = xv;
        float yv = 3 + dd.data[0]*xv;
        for (NSUInteger j=1;j<d;j++) {
            mxv *= xv;
            yv += dd.data[j] * mxv;
        }
        yv += (drand48()-0.5)*1;
    
        [*x setValue:xv atIndex:i];
        [*y setValue:yv atIndex:i];
        NSLog(@"%f,%f",xv,yv);
    }
}
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSError *err = nil;
    self.days = [self readFromCSV];
    NSArray *lastMonth = [self.days subarrayWithRange:NSMakeRange(self.days.count-30, 30)];
    NSArray *pressure = [lastMonth mapArrayWithBlock:^id(NSDictionary* object, NSUInteger idx) {
        float p9 = [[object objectForKey:@"Pressure9"] floatValue];
        float p15 = [[object objectForKey:@"Pressure15"] floatValue];
        return @((p9-p15));
    }];
    NSArray *rainfall = [lastMonth mapArrayWithBlock:^id(NSDictionary* object, NSUInteger idx) {
        return [object objectForKey:@"Rainfall"];
       // return ([[object objectForKey:@"Rainfall"] floatValue] > 0) ? @(1) : @(0);
    }];
    AVVector *press = [pressure toFloatVector];
    //AVVector *press_lag = [press lagVectorBy:1];
    //[press_lag multiplyByScalar:-1.];
    //AVVector *p = [AVVector sumVector:press with:press_lag error:&err];
    //[p setValue:0 value:0];
    AVVector *p = press;
    AVVector *r = [[rainfall toFloatVector] lagVectorBy:1];
    //calculation of correlation
    float mp = [p mean];
    float mr = [r mean];
    
    AVVector *mpv = [[AVVector alloc] initWithLength:p.length setAllValuesTo:-mp];
    AVVector *mrv = [[AVVector alloc] initWithLength:r.length setAllValuesTo:-mr];
    AVVector *a = [AVVector sumVector:p with:mpv error:&err];
    AVVector *b = [AVVector sumVector:r with:mrv error:&err];
    float ab = [AVVector dotVector:a by:b error:&err];
    AVVector *a2 = [a vectorOfPower2];
    AVVector *b2 = [b vectorOfPower2];
    float a2sum = [a2 sumElements];
    float b2sum = [b2 sumElements];
    float corr = ab / sqrtf(a2sum * b2sum);
    NSLog(@"Correlation : %f",corr);
    //square vector vDSP_vsq
    [self.graphView setFloatScatterPlotData:[r data] xvalues:[p data] length:[p length]];
    //[self.graphView setFloatData:[p data] length:[p length]];
    //[self.graphView setExtraFloatData:[r data] length:[r length]];
    self.graphView.frame = self.view.frame;
}
- (NSArray *)readFromCSV {
    NSError *outError = nil;
    NSString *pathToFile = [[NSBundle mainBundle] pathForResource:@"data1" ofType:@"csv"];
    NSString *fileString = [NSString stringWithContentsOfFile:pathToFile encoding:NSUTF8StringEncoding error:&outError];
    if (!fileString) {
        NSLog(@"Error reading file.");
    }
    NSArray *allLines = [fileString componentsSeparatedByString:@"\n"];
    NSArray *days = [allLines mapArrayWithBlock:^id(id object, NSUInteger idx) {
        return [[self class] processReadLine:object];
    }];
    return days;
}

+ (NSDictionary *)processReadLine:(NSString *)lineStr {
    //,”Date","Minimum temperature (°C)","Maximum temperature (°C)","Rainfall (mm)","Evaporation (mm)","Sunshine (hours)","Direction of maximum wind gust ","Speed of maximum wind gust (km/h)","Time of maximum wind gust","9am Temperature (°C)","9am relative humidity (%)","9am cloud amount (oktas)","9am wind direction","9am wind speed (km/h)","9am MSL pressure (hPa)","3pm Temperature (°C)","3pm relative humidity (%)","3pm cloud amount (oktas)","3pm wind direction","3pm wind speed (km/h)","3pm MSL pressure (hPa)"
    NSArray *comps = [lineStr componentsSeparatedByString:@","];
    if ([comps count]>20) {
        NSDictionary *dayRecord = @{  @"Date" : comps[1],
                                      @"MinTemp" : @([comps[2] floatValue]),
                                      @"MaxTemp" : @([comps[3] floatValue]),
                                      @"Rainfall" : @([comps[4] floatValue]),
                                      @"SunshineHours" : @([comps[6] floatValue]),
                                      @"Humidity9" : @([comps[11] floatValue]),
                                      @"Pressure9" : @([comps[15] floatValue]),
                                      @"Humidity15" : @([comps[17] floatValue]),
                                      @"Pressure15" : @([comps[21] floatValue])
                                     };
        return dayRecord;
    } else {
        NSLog(@"Error str: %@",lineStr);
    }
    return nil;
}
*/
@end
