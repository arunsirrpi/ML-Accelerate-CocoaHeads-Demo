//
//  AVNeuralNetworks.m
//  cameraRecognition
//
//  Created by Alexey Vlaskin on 7/03/2014.
//  Copyright (c) 2014 Alexey Vlaskin. All rights reserved.
//

#import "AVNeuralNetwork.h"
#import "AVVector.h"
#import "Common.h"

@interface AVNeuralNetwork ()

@property (nonatomic, retain) AVVector *layers;

@end

@implementation AVNeuralNetwork

- (instancetype)initWithLayers:(AVVector *)layers
{
    self = [super init];
    if (self)
    {
        NSMutableArray *ar = [NSMutableArray array];
        self.Des = [NSMutableArray array];
        for (NSUInteger i =1;i<layers.length;i++)
        {
            float inputs = [layers valueAt:i-1]+1;
            float outputs =[layers valueAt:i];
            AVMatrix *thetta = [[AVMatrix alloc] initWithRows:outputs cols:inputs];
            AVMatrix *delata = [[AVMatrix alloc] initWithRows:outputs cols:inputs];
            [thetta randomPrefillWithLow:-1.f hi:1.f];
            [ar addObject:thetta];
            [self.Des addObject:delata];
        }
        self.thettas = [NSArray arrayWithArray:ar];
        self.layers = layers;
        self.ais = [NSMutableArray array];
        self.zes = [NSMutableArray array];
        self.deltas = [NSMutableArray array];
        self.lyambda = 0.1f;
    }
    return self;
}
- (AVVector *)computeWithInput:(AVVector *)input error:(NSError **)error
{
    [self.ais removeAllObjects];
    [self.zes removeAllObjects];
    
    AVVector *a = [AVVector addOneWithVector:input];
    [self.ais addObject:a];
    for (AVMatrix *m in self.thettas)
    {
        AVVector *z = [AVMatrix mulMatrix:m byVector:a error:error];
        if (*error) { return nil; }
        [z applyEvaluater:^float(float v) {
            return 1./(1+powf(M_E,-v));
        }];
        [self.zes addObject:z];
        if (![m isEqual:[self.thettas lastObject]])
        {
            a = [AVVector addOneWithVector:z];
        }
        else
        {
            a = z;
        }
        [self.ais addObject:a];
    }
    return a;
}

- (void)computeBackPropagationForExpectedOutput:(AVVector *)output error:(NSError **)error
{
    [self.deltas removeAllObjects];
    NSUInteger n = (NSUInteger)[self.layers valueAt:self.layers.length-1];
    AVVector *aLast = [self.ais lastObject];
    AVVector* d = nil;
    d = [AVVector sumVector:[AVVector multiplyVector:output byScalar:-1] with:aLast error:error];
    if (d.length!=n)
    {
        *error = [NSError errorWithDomain:@"" code:-111 userInfo:nil];
        return;
    }
    [self.deltas addObject:d];
    d = [AVVector addOneWithVector:d]; //tricky part
    for (NSUInteger i = (self.layers.length-1-1);i>0;i--)
    {
        AVMatrix *thetta = self.thettas[i];
        thetta = [AVMatrix transposeMatrix:thetta];
        d = [AVVector removeOneFromVector:d]; //the trickiest part here
        d = [AVMatrix mulMatrix:thetta byVector:d error:error];
        AVVector *a = self.ais[i];
        if (d.length != a.length)
        {
            *error = [NSError errorWithDomain:@"" code:-112 userInfo:nil];
            return;
        }
        [d applyIndexEvaluater:^float(float v, NSUInteger index) {
            float aa = [a valueAt:index];
            return v * aa * (1 - aa);
        }];
        [self.deltas addObject:d];
    }
    self.deltas = [NSMutableArray arrayWithArray:[[self.deltas reverseObjectEnumerator] allObjects]];
}

- (void)computeDeltaThettas:(NSError **)error
{
    NSMutableArray *newDes = [NSMutableArray array];
    for (NSUInteger i = 0;i<self.layers.length-1;i++)
    {
        AVVector *vd = self.deltas[i];
        if (i != (self.layers.length-2))
        {
            vd = [AVVector removeOneFromVector:vd]; //the trickiest part here
        }
        AVMatrix *d = [AVMatrix vectorToMatrix:vd];
        AVMatrix *a = [AVMatrix vectorToMatrix:self.ais[i]];
        a = [AVMatrix transposeMatrix:a];
        
        AVMatrix *D = self.Des[i];

        D = [AVMatrix sumMatrix:D with:[AVMatrix mulMatrix:d by:a error:error] error:error];
        if (*error)
        {
            return;
        }
        [newDes addObject:D];
    }
    self.Des = newDes;
}

- (void)cleanForwardAndBack
{
    self.ais = [NSMutableArray array];
    self.zes = [NSMutableArray array];
    self.deltas = [NSMutableArray array];
}

- (void)cleanAll
{
    [self cleanForwardAndBack];
    [self.Des removeAllObjects];
    self.Des = [NSMutableArray array];
    for (NSUInteger i =1;i<self.layers.length;i++)
    {
        float inputs = [self.layers valueAt:i-1]+1;
        float outputs =[self.layers valueAt:i];
        AVMatrix *delata = [[AVMatrix alloc] initWithRows:outputs cols:inputs];
        [self.Des addObject:delata];
    }
}


 // 0. This method can be called only once after all (x,y) train examples are applied. It should also kill Des
 // 1. Here we should appy regularization for thetta
 
- (void)changeDeltasWithLyambda:(float)lyambda trainingSet:(NSUInteger)samples;
{
    self.lyambda = lyambda; //used for regularisation
    NSMutableArray *newThettas = [NSMutableArray array];
    NSError *error = nil;
    for (NSUInteger i=0;i<[self.thettas count];i++)
    {
        AVMatrix *thettaConst = self.thettas[i];
        AVMatrix *t = [[AVMatrix alloc] initWithRows:thettaConst.rows cols:thettaConst.cols data:thettaConst.data];
        AVMatrix *d = self.Des[i];
        [d multiplyByScalar:-1.f/((float)samples)];
        if (self.lyambda>0.00001f)
        {
            AVMatrix *rt = self.thettas[i];
            AVMatrix *rtl = [AVMatrix mulMatrix:rt byScalar:(-1.f)*self.lyambda/((float)samples)];
            d = [AVMatrix sumMatrix:d with:rtl error:&error];
        }
        t = [AVMatrix sumMatrix:t with:d error:&error];
        [newThettas addObject:t];
    }
    self.thettas = newThettas;
}

- (float)computeCostFunction:(AVMatrix *)inputs
                    outputs:(AVMatrix *)outputs
                      lyambda:(float)lyambda
                      error:(NSError **)error
{
    float sum = 0;
    for (NSUInteger i = 0;i<inputs.cols;i++)
    {
        AVVector *x = [inputs columnToVector:i];
        AVVector *y= [outputs columnToVector:i];
        AVVector *h = [self computeWithInput:x error:error];
        AVVector *o = [[AVVector alloc] initOneWithLength:y.length];
        AVVector *mh= [AVVector multiplyVector:h byScalar:-1.f];
        AVVector *h1= [AVVector sumVector:o with:mh error:error];
        [h applyEvaluater:^float(float v) {
            return logf(v);
        }];
        [h1 applyEvaluater:^float(float v) {
            return logf(v);
        }];
        for (NSUInteger j=0;j<y.length;j++)
        {
            sum += [y valueAt:j]*[h valueAt:j]+(1-[y valueAt:j])*[h1 valueAt:j];
        }
    }
    sum = 1./inputs.cols*sum;
    return sum;
}

- (NSDictionary *)toDictionary
{
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    [json setValue:[self.layers toDictionary] forKey:kLayers];
    NSMutableArray *thettas = [NSMutableArray arrayWithCapacity:[self.thettas count]];
    for (NSUInteger i=0;i<[self.thettas count];i++)
    {
        NSDictionary *t = ((AVMatrix *)self.thettas[i]).toDictionary;
        [thettas addObject:t];
    }
    [json setValue:[NSArray arrayWithArray:thettas] forKey:kThettas];
    return json;
}

+ (AVNeuralNetwork *)fromDictionary:(NSDictionary *)dictionary {
    NSDictionary *l = [dictionary objectForKey:kLayers];
    AVVector *vlayers = [AVVector fromDictionary:l];
    if (vlayers==nil) {
        return nil;
    }
    AVNeuralNetwork *res = [[AVNeuralNetwork alloc] initWithLayers:vlayers];
    NSArray *thettas = [dictionary objectForKey:kThettas];
    if (!([thettas isKindOfClass:[NSArray class]]) || [thettas count]==0) {
        return res;
    }
    if ([res.thettas count] == [thettas count]) {
        NSMutableArray *ts = [NSMutableArray arrayWithCapacity:[thettas count]];
        
        [thettas enumerateObjectsUsingBlock:^(NSDictionary* obj, NSUInteger idx, BOOL *stop) {
            AVMatrix *t = [AVMatrix fromDictionary:obj];
            [ts addObject:t];
        }];
        res.thettas = [NSArray arrayWithArray:ts];
    }
    return res;
}

@end
