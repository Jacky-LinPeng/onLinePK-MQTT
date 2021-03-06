//
//  AABar.h
//  AAChartKit
//
//  Created by An An on 17/1/19.
//  Copyright ยฉ 2017ๅนด An An. All rights reserved.
//*************** ...... SOURCE CODE ...... ***************
//***...................................................***
//*** https://github.com/AAChartModel/AAChartKit        ***
//*** https://github.com/AAChartModel/AAChartKit-Swift  ***
//***...................................................***
//*************** ...... SOURCE CODE ...... ***************

/*
 
 * -------------------------------------------------------------------------------
 *
 * ๐ ๐ ๐ ๐  โโโ   WARM TIPS!!!   โโโ ๐ ๐ ๐ ๐
 *
 * Please contact me on GitHub,if there are any problems encountered in use.
 * GitHub Issues : https://github.com/AAChartModel/AAChartKit/issues
 * -------------------------------------------------------------------------------
 * And if you want to contribute for this project, please contact me as well
 * GitHub        : https://github.com/AAChartModel
 * StackOverflow : https://stackoverflow.com/users/12302132/codeforu
 * JianShu       : https://www.jianshu.com/u/f1e6753d4254
 * SegmentFault  : https://segmentfault.com/u/huanghunbieguan
 *
 * -------------------------------------------------------------------------------
 
 */

#import <Foundation/Foundation.h>

@class AADataLabels;

@interface AABar : NSObject

AAPropStatementAndPropSetFuncStatement(copy,   AABar, NSString *,     name)
AAPropStatementAndPropSetFuncStatement(strong, AABar, NSArray  *,     data)
AAPropStatementAndPropSetFuncStatement(copy,   AABar, NSString *,     color)
AAPropStatementAndPropSetFuncStatement(assign, AABar, BOOL,           grouping) //Whether to group non-stacked columns or to let them render independent of each other. Non-grouped columns will be laid out individually and overlap each other. default๏ผtrue.
AAPropStatementAndPropSetFuncStatement(strong, AABar, NSNumber *,     pointPadding) //Padding between each column or bar, in x axis units. default๏ผ0.1.
AAPropStatementAndPropSetFuncStatement(strong, AABar, NSNumber *,     pointPlacement) //Padding between each column or bar, in x axis units. default๏ผ0.1.
AAPropStatementAndPropSetFuncStatement(strong, AABar, NSNumber *,     groupPadding) //Padding between each value groups, in x axis units. default๏ผ0.2.
AAPropStatementAndPropSetFuncStatement(strong, AABar, NSNumber *,     borderWidth)
AAPropStatementAndPropSetFuncStatement(assign, AABar, BOOL,           colorByPoint) //ๅฏนๆฏไธชไธๅ็็น่ฎพ็ฝฎ้ข่ฒ(ๅฝๅพ่กจ็ฑปๅไธบ AABar ๆถ,่ฎพ็ฝฎไธบ AABar ๅฏน่ฑก็ๅฑๆง,ๅฝๅพ่กจ็ฑปๅไธบ bar ๆถ,ๅบ่ฏฅ่ฎพ็ฝฎไธบ bar ๅฏน่ฑก็ๅฑๆงๆๆๆ)
AAPropStatementAndPropSetFuncStatement(strong, AABar, AADataLabels *, dataLabels)
AAPropStatementAndPropSetFuncStatement(copy,   AABar, NSString *,     stacking)
AAPropStatementAndPropSetFuncStatement(strong, AABar, NSNumber *,     borderRadius)
AAPropStatementAndPropSetFuncStatement(strong, AABar, NSNumber *,     yAxis)

@end
