//
//  NSObject+LXD_KVO.m
//  LXD_KeyValueObserveDemo
//
//  Created by linxinda on 15/3/15.
//  Copyright (c) 2015年 Personal. All rights reserved.
//

#import "NSObject+LXD_KVO.h"
#import <objc/runtime.h>
#import <objc/message.h>

#import <UIKit/UIKit.h>
//as prefix string of kvo class
static NSString * const kLXDkvoClassPrefix = @"LXDObserver_";
static NSString * const kLXDkvoAssiociateObserver = @"LXDAssiociateObserver";

@interface LXD_ObserverInfo : NSObject

@property (nonatomic, weak) NSObject * observer;
@property (nonatomic, copy) NSString * key;
@property (nonatomic, copy) LXD_ObservingHandler handler;

@end


@implementation LXD_ObserverInfo

- (instancetype)initWithObserver: (NSObject *)observer forKey: (NSString *)key observeHandler: (LXD_ObservingHandler)handler
{
    if (self = [super init]) {
        _observer = observer;
        _key = key;
        _handler = handler;
    }
    return self;
}

@end



#pragma mark -- Debug Method
static NSArray * ClassMethodsName(Class class)
{
    NSMutableArray * methodsArr = [NSMutableArray array];
    
    unsigned methodCount = 0;
    Method * methodList = class_copyMethodList(class, &methodCount);
    for (int i = 0; i < methodCount; i++) {
        
        [methodsArr addObject: NSStringFromSelector(method_getName(methodList[i]))];
    }
    free(methodList);
    
    return methodsArr;
}



#pragma mark -- Transform setter or getter to each other Methods
static NSString * setterForGetter(NSString * getter)
{
    if (getter.length <= 0) { return nil; }
    NSString * firstString = [[getter substringToIndex: 1] uppercaseString];
    NSString * leaveString = [getter substringFromIndex: 1];
    
    return [NSString stringWithFormat: @"set%@%@:", firstString, leaveString];
}


static NSString * getterForSetter(NSString * setter)
{
    if (setter.length <= 0 || ![setter hasPrefix: @"set"] || ![setter hasSuffix: @":"]) {
        
        return nil;
    }
    
    NSRange range = NSMakeRange(3, setter.length - 4);
    NSString * getter = [setter substringWithRange: range];
    
    NSString * firstString = [[getter substringToIndex: 1] lowercaseString];
    getter = [getter stringByReplacingCharactersInRange: NSMakeRange(0, 1) withString: firstString];
    
    return getter;
}


#pragma mark -- Override setter and getter Methods

#define KVO_SETTERR(_obj, _sel, _newValue, _valueType, _newIDValue)\
    NSString * setterName = NSStringFromSelector(_sel);\
    NSString * getterName = getterForSetter(setterName);\
    if (!getterName) {\
        @throw [NSException exceptionWithName: NSInvalidArgumentException reason: [NSString stringWithFormat: @"unrecognized selector sent to instance %p", _obj] userInfo: nil];\
        return;\
    }\
    \
    id oldValue = [_obj valueForKey: getterName];\
    struct objc_super superClass = {\
        .receiver = _obj,\
        .super_class = class_getSuperclass(object_getClass(_obj))\
    };\
    \
    [_obj willChangeValueForKey: getterName];\
    void (*objc_msgSendSuperKVO)(void *, SEL, _valueType) = (void *)objc_msgSendSuper;\
    objc_msgSendSuperKVO(&superClass, _sel, _newValue);\
    [_obj didChangeValueForKey: getterName];\
    \
    NSMutableArray *observers = objc_getAssociatedObject(_obj, (__bridge const void *)kLXDkvoAssiociateObserver);\
    for (LXD_ObserverInfo * info in observers) {\
        if ([info.key isEqualToString: getterName]) {\
            dispatch_async(dispatch_queue_create(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{\
                info.handler(_obj, getterName, oldValue, _newIDValue);\
            });\
        }\
    }\

static void KVO_setter_id(id self, SEL _cmd, id newValue) {
    KVO_SETTERR(self, _cmd, newValue, id ,newValue);
}


#define KVO_SetterNumber_NameAndType(typeName, type) \
static void KVO_setterNumber_##typeName(id self, SEL _cmd, type newValue) {\
    id newObjValue = @(newValue);\
    KVO_SETTERR(self,_cmd,newValue,type,newObjValue);\
}\

#define KVO_SetterValue_NameAndType(typeName, type) \
static void KVO_setterValue_##typeName(id self, SEL _cmd, type newValue) {\
    id newObjValue = [NSValue value:&newValue withObjCType:@encode(type)];\
    KVO_SETTERR(self,_cmd,newValue,type,newObjValue);\
}\

#define KVO_SetterNumber_Type(type) KVO_SetterNumber_NameAndType(type, type)
#define KVO_SetterValue_Type(type) KVO_SetterValue_NameAndType(type, type)

KVO_SetterNumber_Type(char)
KVO_SetterNumber_NameAndType(UnsignedChar,unsigned char)
KVO_SetterNumber_Type(short)
KVO_SetterNumber_NameAndType(UnsignedShort,unsigned short)
KVO_SetterNumber_Type(int)
KVO_SetterNumber_NameAndType(UnsignedInt,unsigned int)
KVO_SetterNumber_Type(long)
KVO_SetterNumber_NameAndType(UnsignedLong,unsigned long)
KVO_SetterNumber_NameAndType(LongLong,long long)
KVO_SetterNumber_NameAndType(UnsignedLongLong,unsigned long long)
KVO_SetterNumber_Type(NSInteger)
KVO_SetterNumber_Type(NSUInteger)
KVO_SetterNumber_Type(CGFloat)
KVO_SetterNumber_Type(float)
KVO_SetterNumber_Type(double)
KVO_SetterNumber_Type(BOOL)

KVO_SetterValue_Type(CGPoint)
KVO_SetterValue_Type(CGVector)
KVO_SetterValue_Type(CGSize)
KVO_SetterValue_Type(CGRect)
KVO_SetterValue_Type(CGAffineTransform)
KVO_SetterValue_Type(UIEdgeInsets)
KVO_SetterValue_Type(UIOffset)
KVO_SetterValue_Type(NSRange)
KVO_SetterValue_Type(CATransform3D)

static Class kvo_Class(id self)
{
    return class_getSuperclass(object_getClass(self));
}

#pragma mark -- NSObject Category(KVO Reconstruct)
@implementation NSObject (LXD_KVO)

- (void)LXD_addObserver:(NSObject *)observer forKey:(NSString *)key withBlock:(LXD_ObservingHandler)observedHandler
{
    //step 1 get setter method, if not, throw exception
    SEL setterSelector = NSSelectorFromString(setterForGetter(key));
    Method setterMethod = class_getInstanceMethod([self class], setterSelector);
    if (!setterMethod) {
        @throw [NSException exceptionWithName: NSInvalidArgumentException reason: [NSString stringWithFormat: @"unrecognized selector sent to instance %@", self] userInfo: nil];
        return;
    }
    Class observedClass = object_getClass(self);
    NSString * className = NSStringFromClass(observedClass);
    
    //如果被监听者没有LXDObserver_，那么判断是否需要创建新类
    if (![className hasPrefix: kLXDkvoClassPrefix]) {
        observedClass = [self createKVOClassWithOriginalClassName: className];
        
        //将self 转换成observedClass类型，返回原来的类型
        object_setClass(self, observedClass);
        
        //self 是一个监听对象了
    }
    
    //add kvo setter method if its class(or superclass)hasn't implement setter
    if (![self hasSelector: setterSelector]) {
        //在类中添加方法和实现
        const char * types = method_getTypeEncoding(setterMethod);
        
        Class observedClass = object_getClass(self);
        objc_property_t property_t = class_getProperty(observedClass, key.UTF8String);
        
        NSString *attributes = [NSString stringWithCString:property_getAttributes(property_t) encoding:NSUTF8StringEncoding];
        
        IMP setterIMP;
        if ([attributes hasPrefix:@"T@"]) {
            setterIMP = (IMP)KVO_setter_id;
        }else if ([attributes hasPrefix:@"T{"]) {
            if ([attributes hasPrefix:@"T{CGPoint"]) {
                setterIMP = (IMP)KVO_setterValue_CGPoint;
            }
            else if ([attributes hasPrefix:@"T{CGRect"]) {
                setterIMP = (IMP)KVO_setterValue_CGRect;
            }
            else if ([attributes hasPrefix:@"T{CGVector"]) {
                setterIMP = (IMP)KVO_setterValue_CGVector;
            }
            else if ([attributes hasPrefix:@"T{CGSize"]) {
                setterIMP = (IMP)KVO_setterValue_CGSize;
            }
            else if ([attributes hasPrefix:@"T{CGAffineTransform"]) {
                setterIMP = (IMP)KVO_setterValue_CGAffineTransform;
            }
            else if ([attributes hasPrefix:@"T{UIEdgeInsets"]) {
                setterIMP = (IMP)KVO_setterValue_UIEdgeInsets;
            }
            else if ([attributes hasPrefix:@"T{UIOffset"]) {
                setterIMP = (IMP)KVO_setterValue_UIOffset;
            }
            else if ([attributes hasPrefix:@"T{_NSRange"]) {
                setterIMP = (IMP)KVO_setterValue_NSRange;
            }
            else if ([attributes hasPrefix:@"T{CATransform3D"]) {
                setterIMP = (IMP)KVO_setterValue_CATransform3D;
            }else {
                NSAssert(NO, @"Can't identify Struct");
            }
        }else {
            if ([attributes hasPrefix:@"Tc"]) {
                setterIMP = (IMP)KVO_setterNumber_char;
            }
            else if ([attributes hasPrefix:@"TC"]) {
                setterIMP = (IMP)KVO_setterNumber_UnsignedChar;
            }
            else if ([attributes hasPrefix:@"Ts"]) {
                setterIMP = (IMP)KVO_setterNumber_short;
            }
            else if ([attributes hasPrefix:@"TS"]) {
                setterIMP = (IMP)KVO_setterNumber_UnsignedShort;
            }
            else if ([attributes hasPrefix:@"Ti"]) {
                setterIMP = (IMP)KVO_setterNumber_int;
            }
            else if ([attributes hasPrefix:@"TI"]) {
                setterIMP = (IMP)KVO_setterNumber_UnsignedInt;
            }
            else if ([attributes hasPrefix:@"Tq"]) {
                setterIMP = (IMP)KVO_setterNumber_long;
            }
            else if ([attributes hasPrefix:@"TQ"]) {
                setterIMP = (IMP)KVO_setterNumber_UnsignedLong;
            }
            else if ([attributes hasPrefix:@"Tf"]) {
                setterIMP = (IMP)KVO_setterNumber_float;
            }
            else if ([attributes hasPrefix:@"Td"]) {
                setterIMP = (IMP)KVO_setterNumber_double;
            }
            else if ([attributes hasPrefix:@"TB"]) {
                setterIMP = (IMP)KVO_setterNumber_BOOL;
            }else{
                NSAssert(NO, @"Can't identify Basic data types");
            }
        }
        class_addMethod(observedClass, setterSelector, setterIMP, types);
    }
    
    //add this observation info to saved new observer
    LXD_ObserverInfo * newInfo = [[LXD_ObserverInfo alloc] initWithObserver: observer forKey: key observeHandler: observedHandler];
    NSMutableArray * observers = objc_getAssociatedObject(self, (__bridge void *)kLXDkvoAssiociateObserver);
    
    if (!observers) {
        observers = [NSMutableArray array];
        objc_setAssociatedObject(self, (__bridge void *)kLXDkvoAssiociateObserver, observers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    [observers addObject: newInfo];
}


- (void)LXD_removeObserver:(NSObject *)object forKey:(NSString *)key
{
    NSMutableArray * observers = objc_getAssociatedObject(self, (__bridge void *)kLXDkvoAssiociateObserver);
    
    
    NSMutableArray *observerList = [NSMutableArray arrayWithCapacity:0];
    for (LXD_ObserverInfo * observerInfo in observers) {
        
        if (observerInfo.observer == object && [observerInfo.key isEqualToString: key]) {
            
            [observerList addObject:observerInfo];
        }
    }
    [observers removeObjectsInArray:observerList];
}


- (Class)createKVOClassWithOriginalClassName: (NSString *)className
{
    NSString * kvoClassName = [kLXDkvoClassPrefix stringByAppendingString: className];
    Class observedClass = NSClassFromString(kvoClassName);
    
    if (observedClass) { return observedClass; }
    
    //创建新类，并且添加LXDObserver_为类名新前缀
    Class originalClass = object_getClass(self);
    Class kvoClass = objc_allocateClassPair(originalClass, kvoClassName.UTF8String, 0);
    
    //获取监听对象的class方法实现代码，然后替换新建类的class实现
    Method classMethod = class_getInstanceMethod(originalClass, @selector(class));
    const char * types = method_getTypeEncoding(classMethod);
    class_addMethod(kvoClass, @selector(class), (IMP)kvo_Class, types);
    objc_registerClassPair(kvoClass);
    return kvoClass;
}


- (BOOL)hasSelector: (SEL)selector
{
    Class observedClass = object_getClass(self);
    unsigned int methodCount = 0;
    Method * methodList = class_copyMethodList(observedClass, &methodCount);
    for (int i = 0; i < methodCount; i++) {
        
        SEL thisSelector = method_getName(methodList[i]);
        if (thisSelector == selector) {
            
            free(methodList);
            return YES;
        }
    }
    
    free(methodList);
    return NO;
}

@end
