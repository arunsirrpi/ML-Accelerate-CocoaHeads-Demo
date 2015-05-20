//
//  AVNeuralNetwork+Tests.m
//  weatherPrediction
//
//  Created by Alexey Vlaskin on 13/05/2015.
//  Copyright (c) 2015 Alexey Vlaskin. All rights reserved.
//

#import "AVNeuralNetwork+Tests.h"
#import "AVVector.h"
#import "AVMatrix.h"

@implementation AVNeuralNetwork (Tests)

+ (void)neuralNetworkTest
{
    float d[] = { 2, 1 };
    float th[] = { -30, 20, 20 };
    float input1[] = { 0, 0 };
    float input2[] = { 1, 0 };
    float input3[] = { 0, 1 };
    float input4[] = { 1, 1 };
    AVVector *layers = [[AVVector alloc] initWithLength:2 data:d];
    AVNeuralNetwork *net = [[AVNeuralNetwork alloc] initWithLayers:layers];
    AVMatrix *thetta = [[AVMatrix alloc] initWithRows:1 cols:3 data:th];
    net.thettas = [NSArray arrayWithObject:thetta]; //hack it
    AVVector *inputV1 = [[AVVector alloc] initWithLength:2 data:input1];
    AVVector *inputV2 = [[AVVector alloc] initWithLength:2 data:input2];
    AVVector *inputV3 = [[AVVector alloc] initWithLength:2 data:input3];
    AVVector *inputV4 = [[AVVector alloc] initWithLength:2 data:input4];
    
    
    NSError *error = nil;
    NSLog(@"**** AND Neural network test ****");
    AVVector *result1 = [net computeWithInput:inputV1 error:&error];
    NSLog(@"Test 1 Net  %@",[result1 description]);
    AVVector *result2 = [net computeWithInput:inputV2 error:&error];
    NSLog(@"Test 2 Net  %@",[result2 description]);
    AVVector *result3 = [net computeWithInput:inputV3 error:&error];
    NSLog(@"Test 3 Net  %@",[result3 description]);
    AVVector *result4 = [net computeWithInput:inputV4 error:&error];
    NSLog(@"Test 4 Net  %@",[result4 description]);
    ///another test
    
    float ll[] = { 2, 2 , 3, 1 };
    AVVector *layers2 = [[AVVector alloc] initWithLength:4 data:ll];
    AVNeuralNetwork *net2 = [[AVNeuralNetwork alloc] initWithLayers:layers2];
    //training set
    float res[4] = { 1,1,0,0};
    float input11[] = { 0, 1 }; AVVector *inputV11 = [[AVVector alloc] initWithLength:2 data:input11];
    float input12[] = { 1, 0 }; AVVector *inputV12 = [[AVVector alloc] initWithLength:2 data:input12];
    float input13[] = { 0, 0 }; AVVector *inputV13 = [[AVVector alloc] initWithLength:2 data:input13];
    float input14[] = { 1, 1 }; AVVector *inputV14 = [[AVVector alloc] initWithLength:2 data:input14];
    float inputs[] = {0,1,0,1,1,0,0,1};
    AVMatrix *inputsM = [[AVMatrix alloc] initWithRows:2 cols:4 data:inputs];
    AVMatrix *outputsM= [[AVMatrix alloc] initWithRows:1 cols:4 data:res];
    
    NSLog(@"**** Another Neural network test ****");
    float before = 1000;
    float after = 100;
    int i = 0;
    net2.lyambda = 0.0001;
    do
    {
        before = [net2 computeCostFunction:inputsM outputs:outputsM lyambda:0 error:&error];
        AVVector *result11 = [net2 computeWithInput:inputV11 error:&error];
        [net2 computeBackPropagationForExpectedOutput:[[AVVector alloc] initWithLength:1 data:&res[0]] error:&error];
        [net2 computeDeltaThettas:&error];
        [net2 cleanForwardAndBack];
        
        AVVector *result12 = [net2 computeWithInput:inputV12 error:&error];
        [net2 computeBackPropagationForExpectedOutput:[[AVVector alloc] initWithLength:1 data:&res[1]] error:&error];
        [net2 computeDeltaThettas:&error];
        [net2 cleanForwardAndBack];
        
        AVVector *result13 = [net2 computeWithInput:inputV13 error:&error];
        [net2 computeBackPropagationForExpectedOutput:[[AVVector alloc] initWithLength:1 data:&res[2]] error:&error];
        [net2 computeDeltaThettas:&error];
        [net2 cleanForwardAndBack];
        
        AVVector *result14 = [net2 computeWithInput:inputV14 error:&error];
        [net2 computeBackPropagationForExpectedOutput:[[AVVector alloc] initWithLength:1 data:&res[3]] error:&error];
        [net2 computeDeltaThettas:&error];
        [net2 cleanForwardAndBack];
        
        [net2 changeDeltasWithLyambda:net2.lyambda trainingSet:4];
        
        if (error)
        {
            return;
        }
        NSLog(@"Itteration results: %d",i);
        NSLog(@"Res1 : %@",[result11 description]);
        NSLog(@"Res2 : %@",[result12 description]);
        NSLog(@"Res3 : %@",[result13 description]);
        NSLog(@"Res4 : %@",[result14 description]);
        after = [net2 computeCostFunction:inputsM outputs:outputsM lyambda:net2.lyambda error:&error];
        NSLog(@"Cost function before:%f after:%f",before,after);
        i++;
    }while ((fabsf(before) > fabsf(after)) && fabsf(after)>0.001f);
    NSLog(@"Network is taught in %d itterations",i);
}


@end
