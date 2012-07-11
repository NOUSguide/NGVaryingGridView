//
//  NGViewController.m
//  NGVaryingGridViewDemo
//
//  Created by Philip Messlehner on 19.04.12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//

#import "NGViewController.h"
#import "NGVaryingGridView.h"
#import "NGTimeTableCell.h"

#define kColumnWidth    ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 200.f : 100.f)
#define kRightPadding   ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 91.f : 46.f)
#define kContentHeight  ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 1600.f : 800.f)

@interface NGViewController () <NGVaryingGridViewDelegate>

@property (nonatomic, strong) NGVaryingGridView *gridView;
@property (nonatomic, strong) NSMutableArray *events;

@end

@implementation NGViewController

@synthesize gridView = _gridView;
@synthesize events = _events;

////////////////////////////////////////////////////////////////////////
#pragma mark - Life Cycle
////////////////////////////////////////////////////////////////////////

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        _events = [NSArray arrayWithObjects:
                   [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSNumber numberWithFloat:1.5f], @"begin",
                    [NSNumber numberWithFloat:0.75f], @"duration",
                    [NSNumber numberWithInt:0], @"day",
                    @"08:30 Programming Language Lecture", @"title", nil],
                   [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSNumber numberWithFloat:4.f], @"begin",
                    [NSNumber numberWithFloat:2.5f], @"duration",
                    [NSNumber numberWithInt:0], @"day",
                    @"11:00 Workout", @"title", nil],
                   [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSNumber numberWithFloat:4.5f], @"begin",
                    [NSNumber numberWithFloat:0.5f], @"duration",
                    [NSNumber numberWithInt:1], @"day",
                    @"12:30 Brunch with Lisa", @"title", nil],
                   [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSNumber numberWithFloat:2.f], @"begin",
                    [NSNumber numberWithFloat:4.5f], @"duration",
                    [NSNumber numberWithInt:2], @"day",
                    @"09:00 @Work", @"title", nil],
                   [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSNumber numberWithFloat:1.f], @"begin",
                    [NSNumber numberWithFloat:2.f], @"duration",
                    [NSNumber numberWithInt:4], @"day",
                    @"08:00 Security Lecture", @"title", nil],
                   nil];
    }
    
    return self;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - UIViewController
////////////////////////////////////////////////////////////////////////

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
	
    self.gridView = [[NGVaryingGridView alloc] initWithFrame:self.view.bounds];
    self.gridView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.gridView.gridViewDelegate = self;
    [self.view addSubview:self.gridView];
    
    UIView *timeLine = [[UIView alloc] initWithFrame:CGRectMake(-1.f, -600.f, kRightPadding + 1.f, kContentHeight + 600.f)];
    CALayer *layer = timeLine.layer;
	layer.masksToBounds = NO;
	layer.borderWidth = 1.f;
	layer.borderColor = [[UIColor blackColor] CGColor];
	layer.shadowOffset = CGSizeMake(5.f, 0.f);
	layer.shadowRadius = 5.f;
	layer.shadowOpacity = 0.5f;
    
    timeLine.backgroundColor = [UIColor grayColor];
    for (int i = 0; i < 7; i++) {
        UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.f, 600.f + kContentHeight / 8.f * (i+1), timeLine.frame.size.width, 40.f)];
        timeLabel.backgroundColor = [UIColor clearColor];
        timeLabel.textColor = [UIColor whiteColor];
        timeLabel.textAlignment = UITextAlignmentCenter;
        timeLabel.text = [NSString stringWithFormat:@"%02d:00", i+8];
        timeLabel.font = [UIFont boldSystemFontOfSize:12.f];
        timeLabel.shadowColor = [UIColor darkGrayColor];
        timeLabel.shadowOffset = CGSizeMake(1.f, 1.f);
        [timeLine addSubview:timeLabel];
    }
    
    UIView *dayLine = [[UIView alloc] initWithFrame:CGRectMake(-600.f, -1.f, kColumnWidth * 5.f + kRightPadding + 1200.f, kContentHeight / 8.f)];
    dayLine.backgroundColor = [UIColor grayColor];
    layer = dayLine.layer;
	layer.masksToBounds = NO;
	layer.borderWidth = 1.f;
	layer.borderColor = [[UIColor blackColor] CGColor];
	layer.shadowOffset = CGSizeMake(5.f, 0.f);
	layer.shadowRadius = 5.f;
	layer.shadowOpacity = 0.5f;
    
    UIView *grayView = [[UIView alloc] initWithFrame:CGRectMake(-600.f, dayLine.frame.size.height / 2.f, dayLine.frame.size.width + 1200.f, dayLine.frame.size.height / 2.f)];
    grayView.backgroundColor = [UIColor lightGrayColor];
    layer = grayView.layer;
	layer.masksToBounds = NO;
	layer.borderWidth = 1.f;
	layer.borderColor = [[UIColor blackColor] CGColor];
    [dayLine addSubview:grayView];
    NSArray *days = [NSArray arrayWithObjects:@"Monday", @"Tuesday", @"Wednesday", @"Thursday", @"Friday", nil];
    for (int i = 0; i < 5; i++) {
        UILabel *dayLabel = [[UILabel alloc] initWithFrame:CGRectMake(i * kColumnWidth + timeLine.frame.size.width + 600.f, 0.f, kColumnWidth, grayView.frame.size.height)];
        dayLabel.backgroundColor = [UIColor clearColor];
        dayLabel.textColor = [UIColor whiteColor];
        dayLabel.textAlignment = UITextAlignmentCenter;
        dayLabel.text = [days objectAtIndex:i];
        dayLabel.font = [UIFont boldSystemFontOfSize:12.f];
        dayLabel.shadowColor = [UIColor darkGrayColor];
        dayLabel.shadowOffset = CGSizeMake(1.f, 1.f);
        [dayLine addSubview:dayLabel];
    }
    
    NGTimeTableCell *wholeDayEvent = [[NGTimeTableCell alloc] initWithFrame:CGRectMake(600.f + kRightPadding + 0 * kColumnWidth + 5.f, kContentHeight / 16.f + 5.f, 2 * kColumnWidth - 10.f, kContentHeight / 16.f - 10.f)];
    wholeDayEvent.backgroundColor = [UIColor blueColor];
    wholeDayEvent.text = @"Vacation";
    [dayLine addSubview:wholeDayEvent];
    
    [self.gridView setStickyView:dayLine lockPosition:NGVaryingGridViewLockPositionTop];
    [self.gridView setStickyView:timeLine lockPosition:NGVaryingGridViewLockPositionLeft];
    
    [self.gridView reloadData];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    self.gridView.gridViewDelegate = nil;
    self.gridView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - NGVaryingGridViewDelegate
////////////////////////////////////////////////////////////////////////

- (NSArray *)rectsForCellsInGridView:(NGVaryingGridView *)gridView {
    NSMutableArray *rectsArray = [NSMutableArray array];
    for (NSDictionary *event in self.events) {
        [rectsArray addObject:[NSValue valueWithCGRect:CGRectMake(kRightPadding + 5.f + [[event objectForKey:@"day"] floatValue] * kColumnWidth, [[event objectForKey:@"begin"] floatValue] * kContentHeight / 8 + 5.f, kColumnWidth - 10.f, [[event objectForKey:@"duration"] floatValue] * kContentHeight / 8 - 10.f)]];
    }
    return rectsArray;
}

- (UIView *)gridView:(NGVaryingGridView *)gridView viewForCellWithRect:(CGRect)rect index:(NSUInteger)index {
    NGTimeTableCell *cell = (NGTimeTableCell *) ([gridView dequeueReusableCellWithFrame:rect] ?: [[NGTimeTableCell alloc] initWithFrame:rect]);
    
    NSDictionary *event = [self.events objectAtIndex:index];
    cell.text = [event objectForKey:@"title"];
    return cell;
}

- (void)gridView:(NGVaryingGridView *)gridView didSelectCell:(UIView *)cell index:(NSUInteger)index {
    NSLog(@"You selected a cell!");
}

- (void)gridView:(NGVaryingGridView *)gridView willPrepareCellForReuse:(UIView *)cell {
    
}

@end
