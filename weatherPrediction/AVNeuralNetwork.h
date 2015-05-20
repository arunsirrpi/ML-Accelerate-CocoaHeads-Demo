//
//  AVNeuralNetworks.h
//  cameraRecognition
//
//  Created by Alexey Vlaskin on 7/03/2014.
//  Copyright (c) 2014 Alexey Vlaskin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AVMatrix.h"

@interface AVNeuralNetwork : NSObject

//should be protected
@property (nonatomic, retain) NSArray *thettas;
@property (nonatomic, retain) NSMutableArray *ais;
@property (nonatomic, retain) NSMutableArray *zes;
@property (nonatomic, retain) NSMutableArray *deltas;
@property (nonatomic, retain) NSMutableArray *Des;
@property (nonatomic, assign) float lyambda;

- (instancetype)initWithLayers:(AVVector *)layers;//vector sets how many layers, and how many neurons in each
- (AVVector *)computeWithInput:(AVVector *)input error:(NSError **)error;
- (void)computeBackPropagationForExpectedOutput:(AVVector *)output error:(NSError **)error;
- (float)computeCostFunction:(AVMatrix *)inputs
                    outputs:(AVMatrix *)outputs
                    lyambda:(float)lyambda error:(NSError **)error;
- (void)computeDeltaThettas:(NSError **)error;
- (void)changeDeltasWithLyambda:(float)lyambda trainingSet:(NSUInteger)samples;
- (void)cleanAll;
- (void)cleanForwardAndBack;

- (NSDictionary *)toDictionary;
+ (AVNeuralNetwork *)fromDictionary:(NSDictionary *)dictionary;

@end
