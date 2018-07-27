/***************************************************************************
 
UIView+Toast.h
Toast

Copyright (c) 2014 Charles Scalesse.
 
Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:
 
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
***************************************************************************/

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
  ToastPositionTop,
  ToastPositionCenter,
  ToastPositionBottom,
} ToastPosition;

@interface UIView (Toast)

  // 单独显示在Windows界面上,需要自己清除弹出框
+(UIView *)ToastWindowsMessage:(NSString *)message;

// each makeToast method creates a view and displays it as toast
- (void)makeToast:(NSString *)message;
- (void)makeToast:(NSString *)message duration:(NSTimeInterval)interval position:(ToastPosition)position;
- (void)makeToast:(NSString *)message duration:(NSTimeInterval)interval position:(ToastPosition)position image:(UIImage *)image;
- (void)makeToast:(NSString *)message duration:(NSTimeInterval)interval position:(ToastPosition)position title:(NSString *)title;
- (void)makeToast:(NSString *)message duration:(NSTimeInterval)interval position:(ToastPosition)position title:(NSString *)title image:(UIImage *)image;
- (void)makeToast:(NSString *)message duration:(NSTimeInterval)duration position:(ToastPosition)position title:(NSString *)title image:(UIImage *)image tapCallback:(void(^)(void))tapCallback;

// displays toast with an activity spinner
- (void)makeToastActivity;
- (void)makeToastActivity:(ToastPosition)position;
- (void)hideToastActivity;

// the showToast methods display any view as toast
- (void)showToast:(UIView *)toast;
- (void)showToast:(UIView *)toast duration:(NSTimeInterval)interval position:(ToastPosition)point;
  // 单例模式
- (void)showToast:(UIView *)toast duration:(NSTimeInterval)interval position:(ToastPosition)point tapCallback:(void(^)(void))tapCallback;

-(void)hideToast;
@end
