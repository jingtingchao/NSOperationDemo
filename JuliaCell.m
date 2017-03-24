//  Copyright (c) 2012 Rob Napier
//
//  This code is licensed under the MIT License:
//
//  Permission is hereby granted, free of charge, to any person obtaining a
//  copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//  DEALINGS IN THE SOFTWARE.
//
#import "JuliaCell.h"
#import "JuliaOperation.h"

@interface JuliaCell ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (nonatomic, readwrite, strong) NSMutableArray *operations;
@end

@implementation JuliaCell
//已经被分配的cell如果被重用了，会调用这个方法
//这个在使用cell作为网络访问的代理容器时尤为重要，需要在这里取消前一次的网络请求，不要再给cell发送数据了。
//这里是网络请求的单位，所以当复用cell的时候，这个单元的所有请求就应该被取消.不是队列的所有请求被取消而是当前的单元的所有请求取消
- (void)prepareForReuse {
    //重用了cell，之前这个cell容器正在执行的操作应该被取消
  [self.operations makeObjectsPerformSelector:@selector(cancel)];
    //每一次重用的时候，都会把数组清空
  [self.operations removeAllObjects];
    //清空显示
  self.imageView.image = nil;
  self.label.text = @"";
}

//awakeFromNib 创建数组
- (void)awakeFromNib {
    [super awakeFromNib];
  self.operations = [NSMutableArray new];
}

- (JuliaOperation *)operationForScale:(CGFloat)scale
                                 seed:(NSUInteger)seed {
    //创建操作
  JuliaOperation *op = [[JuliaOperation alloc] init];
    //
  op.contentScaleFactor = scale;
  //获取cell的bounds
  CGRect bounds = self.bounds;
    //width * scale
  op.width = (unsigned)(CGRectGetWidth(bounds) * scale);
    //height * scale
  op.height = (unsigned)(CGRectGetHeight(bounds) * scale);
  //初始化随机数产生器。设定随机数种子用的。
  srandom((unsigned)seed);
  
  op.c = (long double)random()/LONG_MAX + I*(long double)random()/LONG_MAX;  
  op.blowup = random();
  op.rScale = random() % 20;  // Biased, but simple is more important
  op.gScale = random() % 20;
  op.bScale = random() % 20;
    
  __weak JuliaOperation *weakOp = op;
    //操作完成的时候调用
  op.completionBlock = ^{
      //当操作完成的时候，操作并没有被取消的完成
      //当操作不是被取消的操作
      //当操作是被取消的操作，那么即便是操作完成，操作得到的图片也不会使用
      //操作完成的时候一定要做这样的判断
    if (! weakOp.isCancelled) {
        //在主队列添加操作blcok
        //回到主队列中更新UI。
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        JuliaOperation *strongOp = weakOp;
          //如果数组当中包含了这个操作对象
        if (strongOp && [self.operations containsObject:strongOp]) {
          self.imageView.image = strongOp.image;
          self.label.text = strongOp.description;
            //操作正式完成从数组中移除
          [self.operations removeObject:strongOp];
        }
      }];
    }
  };
  
  if (scale < 0.5) {
    op.queuePriority = NSOperationQueuePriorityVeryHigh;
  }
  else if (scale <= 1) {
    op.queuePriority = NSOperationQueuePriorityHigh;
  }
  else {
    op.queuePriority = NSOperationQueuePriorityNormal;
  }
  
  return op;
}
//在这里重新配置请求和显示。将所有的操作放到操作队列中
- (void)configureWithSeed:(NSUInteger)seed
                    queue:(NSOperationQueue *)queue
                   scales:(NSArray *)scales {
  CGFloat maxScale = [[UIScreen mainScreen] scale];
  self.contentScaleFactor = maxScale;

  NSUInteger kIterations = 6;
  CGFloat minScale = maxScale/pow(2, kIterations);

  JuliaOperation *prevOp = nil;
//跟当前的操作之间建立依赖关系
  for (CGFloat scale = minScale; scale <= maxScale; scale *= 2) {
      //这里创建了操作，在操作的main函数中执行操作
    JuliaOperation *op = [self operationForScale:scale seed:seed];
    if (prevOp){
        //添加依赖。
        //当前依赖依赖于上一个依赖
      [op addDependency:prevOp];
    }
      //将所有的操作都添加到数组当中
      //这里获得的是已经在prepareForReuse中清空的数组
    [self.operations addObject:op];
      //将所有的操作都添加到队列当中
    [queue addOperation:op];
    prevOp = op;
  }
}

@end
