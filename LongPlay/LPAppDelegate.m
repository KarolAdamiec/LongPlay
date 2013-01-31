#import "LPAppDelegate.h"
#import "INAppStoreWindow.h"

@interface LPAppDelegate ()

@property (nonatomic, strong, readwrite) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong, readwrite) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong, readwrite) NSManagedObjectContext *managedObjectContext;

@end

@implementation LPAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    self.window.titleBarHeight = 64.0f;
    self.window.verticalTrafficLightButtons = YES;
    self.window.showsTitle = NO;
    self.window.showsBaselineSeparator = NO;
    [self.window.titleBarView addSubview:self.titlebarView];
    
    self.window.titleBarDrawingBlock = ^(BOOL main, CGRect drawingRect, CGPathRef clippingPath) {
        CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
		
		{ // Draw the gradient.
            CGContextAddPath(context, clippingPath);
            CGContextClip(context);
			
			[[[NSGradient alloc] initWithColors:@[[NSColor colorWithDeviceWhite:0.21f alpha:1.0f],
												  [NSColor colorWithDeviceWhite:0.13f alpha:1.0f]]]
			 drawInRect:drawingRect angle:90.0f];
			
			[(main ? self.window.baselineSeparatorColor : self.window.inactiveBaselineSeparatorColor) set];
            [[NSBezierPath bezierPathWithRect:NSMakeRect(0.0, NSMinY(drawingRect), NSWidth(drawingRect), 1.0)] fill];
            
            [[NSColor colorWithDeviceWhite:1.0 alpha:0.12] set];
            [[NSBezierPath bezierPathWithRect:NSMakeRect(0.0, NSMinY(drawingRect) + 1.0f, NSWidth(drawingRect), 1.0)] fill];
        }
        
        { // Draw drop shadow on top.
            CGContextSetStrokeColorWithColor(context, [[NSColor colorWithDeviceWhite:1.0f alpha:0.15f] CGColor]);
            CGContextSetLineWidth(context, 1.0);
            CGContextMoveToPoint(context, 0.0, CGRectGetHeight(drawingRect) - 1);
            CGContextAddLineToPoint(context, CGRectGetWidth(drawingRect) - 1, CGRectGetHeight(drawingRect));
            CGContextStrokePath(context);
        }
        
        { // Draw bottom stroke.
            CGContextSetStrokeColorWithColor(context, [[NSColor colorWithDeviceWhite:0.0f alpha:1.0f] CGColor]);
            CGContextSetLineWidth(context, 1.0);
            CGContextMoveToPoint(context, 0.0, 1);
            CGContextAddLineToPoint(context, CGRectGetWidth(drawingRect), 1);
            CGContextStrokePath(context);
        }
        
        { // Draw the gloss.
            [[NSColor colorWithDeviceWhite:1.0f alpha:0.1f] set];
			[[NSBezierPath bezierPathWithRect:NSMakeRect(0, NSHeight(drawingRect) / 2,
														 NSWidth(drawingRect), NSHeight(drawingRect) / 2)] fill];
        }
    };
}

// Returns the directory the application uses to store the Core Data
// store file. This code uses a directory named "com.ashfurrow.Long_Play"
// in the user's Application Support directory.
- (NSURL *)applicationFilesDirectory {
    NSURL *appSupportURL = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory
																   inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"com.ashfurrow.Long_Play"];
}

// Creates if necessary and returns the managed object model for the application.
- (NSManagedObjectModel *)managedObjectModel {
    if (_managedObjectModel != nil)
        return _managedObjectModel;
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Long_Play" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application. This
// implementation creates and return a coordinator, having added the
// store for the application to it. (The directory for the store is
// created, if necessary.)
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSLog(@"[%@: %@] No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSError *error = nil;
    
    NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
    
    if (!properties) {
        BOOL ok = NO;
        if ([error code] == NSFileReadNoSuchFileError) {
            ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if (!ok) {
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    } else {
        if (![properties[NSURLIsDirectoryKey] boolValue]) {
            // Customize and localize this error.
            NSString *failureDescription = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationFilesDirectory path]];
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:101 userInfo:dict];
            
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    
    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"Long_Play.storedata"];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    if (![coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]) {
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _persistentStoreCoordinator = coordinator;
    
    return _persistentStoreCoordinator;
}

// Returns the managed object context for the application (which is
// already bound to the persistent store coordinator for the application.)
- (NSManagedObjectContext *)managedObjectContext {
    if (_managedObjectContext) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
		NSDictionary *errorInfo = @{NSLocalizedDescriptionKey: @"Failed to initialize the store.",
									NSLocalizedFailureReasonErrorKey : @"There was an error building up the data file."};
        [[NSApplication sharedApplication] presentError:[NSError errorWithDomain:LPErrorDomain
																			code:LPErrorCodeUnknownError
																		userInfo:errorInfo]];
        return nil;
    }
	
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];

    return _managedObjectContext;
}

// Returns the NSUndoManager for the application. In this case, the manager
// returned is that of the managed object context for the application.
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    return self.managedObjectContext.undoManager;
}

// Performs the save action for the application, which is to send the save:
// message to the application's managed object context. Any encountered
// errors are presented to the user.
- (IBAction)saveAction:(id)sender {
    if (![[self managedObjectContext] commitEditing])
        NSLog(@"[%@: %@] Unable to commit editing before saving!", [self class], NSStringFromSelector(_cmd));
    
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error])
        [[NSApplication sharedApplication] presentError:error];
}

// Save changes in the application's managed object context before the application terminates.
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    if (!_managedObjectContext)
        return NSTerminateNow;
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"[%@: %@] Unable to commit editing to terminate!", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    
    if (![[self managedObjectContext] hasChanges])
        return NSTerminateNow;
    
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
        if ([sender presentError:error])
            return NSTerminateCancel;

        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
		
        NSInteger result = [[NSAlert alertWithMessageText:question defaultButton:quitButton
										  alternateButton:cancelButton otherButton:nil
								informativeTextWithFormat:@"%@", info] runModal];
        
        if (result == NSAlertAlternateReturn)
            return NSTerminateCancel;
    }
    return NSTerminateNow;
}

@end
