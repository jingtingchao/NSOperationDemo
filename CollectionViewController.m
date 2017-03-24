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
#import "CollectionViewController.h"
#import "JuliaCell.h"
#include <sys/sysctl.h>

@interface CollectionViewController ()
@property (nonatomic, readwrite, strong) NSOperationQueue *queue;
@property (nonatomic, readwrite, strong) NSArray *scales;
@end

@implementation CollectionViewController
//获取cpu核心数
unsigned int countOfCores() {
  unsigned int ncpu;
  size_t len = sizeof(ncpu);
  sysctlbyname("hw.ncpu", &ncpu, &len, NULL, 0);
  
  return ncpu;
}

- (void)useAllScales {
  CGFloat maxScale = [[UIScreen mainScreen] scale];
  NSUInteger kIterations = 6;
    // 2 /2^6
  CGFloat minScale = maxScale/pow(2, kIterations);
  
  NSMutableArray *scales = [NSMutableArray new];
    //2/2^6 -> 2
  for (CGFloat scale = minScale; scale <= maxScale; scale *= 2) {
    [scales addObject:@(scale)];
  }
  self.scales = scales;
}
//对scales数组进行操作
- (void)useMinimumScales {
    //2/2^6
  self.scales = [self.scales subarrayWithRange:NSMakeRange(0, 1)];
}
/**
 *  交给一个操作队列来处理
 */
- (void)viewDidLoad {
  [super viewDidLoad];
    //创建一个操作队列。
  self.queue = [[NSOperationQueue alloc] init];
    //
  [self useAllScales];

  // No longer needed in iOS 7
    //根据核心数来设置最大并发数
    //支持iOS7以上没有必要再设置maxConcurrentOperationCount
  self.queue.maxConcurrentOperationCount = countOfCores();
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
  return 1000;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  JuliaCell *
  cell = [self.collectionView
          dequeueReusableCellWithReuseIdentifier:@"Julia"
          forIndexPath:indexPath];
    //配置cell的时候，将操作队列传递过去 以及 scales数组传递过去
  [cell configureWithSeed:indexPath.row queue:self.queue scales:self.scales];
  return cell;
}

/**从WillBeginDragging<->WillBeginDragging 两者之间的切换，也是数组内容的切换**/
/**
 *  开始拖拽的时候，取消所有的操作。一旦开始拖拽就取消所有进行的操作
 *
 *  @param scrollView <#scrollView description#>
 */
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
  [self.queue cancelAllOperations];
  [self useMinimumScales];
}
//当开始减速的时候，恢复数组
- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
  [self useAllScales];
}

@end
