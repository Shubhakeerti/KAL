/*
 
 * Copyright (c) 2009 Keith Lazuka
 
 * License: http://www.opensource.org/licenses/mit-license.html
 
 */



#import "KalViewController.h"

#import "KalLogic.h"

#import "KalDataSource.h"

#import "KalDate.h"

#import "KalPrivate.h"



#define PROFILER 0

#if PROFILER

#include <mach/mach_time.h>

#include <time.h>

#include <math.h>

void mach_absolute_difference(uint64_t end, uint64_t start, struct timespec *tp)

{
    
    uint64_t difference = end - start;
    
    static mach_timebase_info_data_t info = {0,0};
    
    
    
    if (info.denom == 0)
        
        mach_timebase_info(&info);
    
    
    
    uint64_t elapsednano = difference * (info.numer / info.denom);
    
    tp->tv_sec = elapsednano * 1e-9;
    
    tp->tv_nsec = elapsednano - (tp->tv_sec * 1e9);
    
}

#endif



NSString *const KalDataSourceChangedNotification = @"KalDataSourceChangedNotification";



@interface KalViewController ()

@property (nonatomic, retain, readwrite) NSDate *initialDate;

@property (nonatomic, retain, readwrite) NSDate *selectedDate;

- (KalView*)calendarView;

@end



@implementation KalViewController



@synthesize dataSource, delegate, initialDate, selectedDate,monthDate,calendarDelegate;
@synthesize followingIndex,previousIndex;


- (id)initWithSelectedDate:(NSDate *)date

{
    
    isFollowingMonth = NO;
    
    isPreviousMonth = YES;
    
    if ((self = [super init])) {
        
        logic = [[KalLogic alloc] initForDate:date];
        
        self.initialDate = date;
        
        self.selectedDate = date;
        self.monthDate = date;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(significantTimeChangeOccurred) name:UIApplicationSignificantTimeChangeNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:KalDataSourceChangedNotification object:nil];
        
    }
    
    return self;
    
}



- (id)init

{
    
    return [self initWithSelectedDate:[NSDate date]];
    
}



- (KalView*)calendarView { return (KalView*)self.view; }



- (void)setDataSource:(id<KalDataSource>)aDataSource

{
    
    if (dataSource != aDataSource) {
        
        dataSource = aDataSource;
        
        tableView.dataSource = dataSource;
        
    }
    
}



- (void)setDelegate:(id<UITableViewDelegate>)aDelegate

{
    
    if (delegate != aDelegate) {
        
        delegate = aDelegate;
        
        tableView.delegate = delegate;
        
    }
    
}



- (void)clearTable

{
    
    [dataSource removeAllItems];
    
    [tableView reloadData];
    
}



- (void)reloadData

{
    
    [dataSource presentingDatesFrom:logic.fromDate to:logic.toDate delegate:self];
    
}



- (void)significantTimeChangeOccurred

{
    
    [[self calendarView] jumpToSelectedMonth];
    
    [self reloadData];
    
}



// -----------------------------------------

#pragma mark KalViewDelegate protocol



- (void)didSelectDate:(KalDate *)date{
    
    self.selectedDate = [date NSDate];
    
    //NSLog(@"Selected Date %@ ",selectedDate);
    
    NSDate *from = [[date NSDate] cc_dateByMovingToBeginningOfDay];
    
    NSDate *to = [[date NSDate] cc_dateByMovingToEndOfDay];
    
    [self clearTable];
    
    [dataSource loadItemsFromDate:from toDate:to];
    
    [tableView reloadData];
    
    [tableView flashScrollIndicators];
    
    if (isFollowingMonth || isPreviousMonth) {
        isFollowingMonth = NO;
        isPreviousMonth = NO;
    }else{
        [calendarDelegate didSelectCalendarDate:selectedDate];
    }
    
}



- (void)showPreviousMonth

{
    isPreviousMonth = YES;
    [self clearTable];
    
    [logic retreatToPreviousMonth];
    
    [[self calendarView] slideDown];
    
    [self reloadData];
    monthDate = selectedDate;
    NSDate *date = [[NSDate alloc]init];
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:NSWeekdayCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:monthDate];
    [components setMonth:[components month]];
    [components setDay:1];
    date = [cal dateFromComponents:components];
    monthDate = date;
    [calendarDelegate didSelectCalendarDate:monthDate];
}
- (void)showFollowingMonth
{
    isFollowingMonth = YES;
    
    [self clearTable];
    
    [logic advanceToFollowingMonth];
    
    [[self calendarView] slideUp];
    
    [self reloadData];
    NSDate *date = [[NSDate alloc] init];
    NSCalendar *cal = [NSCalendar currentCalendar];
    monthDate = selectedDate;
    NSDateComponents *components = [cal components:NSWeekdayCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:monthDate];
    [components setMonth:[components month]];
    [components setDay:1];
    date = [cal dateFromComponents:components];
    monthDate = date;
    [calendarDelegate didSelectCalendarDate:monthDate];
    
}



// -----------------------------------------

#pragma mark KalDataSourceCallbacks protocol



- (void)loadedDataSource:(id<KalDataSource>)theDataSource;

{
    
    NSArray *markedDates = [theDataSource markedDatesFrom:logic.fromDate to:logic.toDate];
    
    NSMutableArray *dates = [[markedDates mutableCopy] autorelease];
    
    for (int i=0; i<[dates count]; i++)
        
        [dates replaceObjectAtIndex:i withObject:[KalDate dateFromNSDate:[dates objectAtIndex:i]]];
    
    
    
    [[self calendarView] markTilesForDates:dates];
    
    [self didSelectDate:self.calendarView.selectedDate];
    
}



// ---------------------------------------

#pragma mark -



- (void)showAndSelectDate:(NSDate *)date

{
    
    if ([[self calendarView] isSliding])
        
        return;
    
    
    
    [logic moveToMonthForDate:date];
    
    
    
#if PROFILER
    
    uint64_t start, end;
    
    struct timespec tp;
    
    start = mach_absolute_time();
    
#endif
    
    
    
    [[self calendarView] jumpToSelectedMonth];
    
    
    
#if PROFILER
    
    end = mach_absolute_time();
    
    mach_absolute_difference(end, start, &tp);
    
    printf("[[self calendarView] jumpToSelectedMonth]: %.1f ms\n", tp.tv_nsec / 1e6);
    
#endif
    
    
    
    [[self calendarView] selectDate:[KalDate dateFromNSDate:date]];
    
    [self reloadData];
    
}



- (NSDate *)selectedDate

{
    
    return [self.calendarView.selectedDate NSDate];
    
}





// -----------------------------------------------------------------------------------

#pragma mark UIViewController



- (void)didReceiveMemoryWarning

{
    
    self.initialDate = self.selectedDate; // must be done before calling super
    
    [super didReceiveMemoryWarning];
    
}



- (void)loadView

{
    
    if (!self.title)
        
        self.title = @"Calendar";
    
    KalView *kalView = [[[KalView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] delegate:self logic:logic] autorelease];
    
    self.view = kalView;
    
    tableView = kalView.tableView;
    
    tableView.dataSource = dataSource;
    
    tableView.delegate = delegate;
    
    [tableView retain];
    
    [kalView selectDate:[KalDate dateFromNSDate:self.initialDate]];
    
    [self reloadData];
    
}



- (void)viewDidUnload

{
    
    [super viewDidUnload];
    
    [tableView release];
    
    tableView = nil;
    
}



- (void)viewWillAppear:(BOOL)animated

{
    
    [super viewWillAppear:animated];
    
    [tableView reloadData];
    
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [tableView flashScrollIndicators];
}
#pragma mark
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationSignificantTimeChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:KalDataSourceChangedNotification object:nil];
    
    [initialDate release];
    
    [selectedDate release];
    
    [logic release];
    
    [tableView release];
    
    [super dealloc];
    
}



@end