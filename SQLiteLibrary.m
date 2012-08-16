//
//  Created by zeraien on 11/11/11.
//
//


#import "SQLiteLibrary.h"


@implementation SQLiteLibrary
{
    NSString* dbFilePath_;
}

+ (void)setDatabaseFileInCache:(NSString *)dbFilename
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *directory = [paths objectAtIndex:0];
    NSString* appFile = [directory stringByAppendingPathComponent:dbFilename];
    [self setDatabaseFile:appFile];

}
+ (void)setDatabaseFileInDocuments:(NSString *)dbFilename
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *directory = [paths objectAtIndex:0];
    NSString* appFile = [directory stringByAppendingPathComponent:dbFilename];
    [self setDatabaseFile:appFile];
}
+ (void)setDatabaseFile:(NSString *)dbFilePath
{
    SQLiteLibrary * me = [self singleton];
    @synchronized (self)
    {
        [me->dbFilePath_ release]; me->dbFilePath_ = nil;

        me->dbFilePath_ = [dbFilePath copy];
    }
}

+ (SQLiteLibrary *)singleton
{
	static SQLiteLibrary *_instance = nil;

	@synchronized (self)
	{
		if (_instance == nil)
		{
			_instance = [[self alloc] init];
		}
	}

	return _instance;
}

- (id)init
{
	self = [super init];
	if (self)
	{
		database = nil;
		lock = [[NSRecursiveLock alloc]init];
	}

	return self;

}

- (void)dealloc
{
    [lock release];
    [super dealloc];
}

+ (BOOL)begin
{
	return [[self singleton] begin];
}
- (BOOL)begin
{
    [lock lock];
    if (database!=nil)
    {
        [self commit];
        [lock lock];
    }

    NSAssert(dbFilePath_!=nil, @"dbFilePath must be set!");

	NSString*dbPath = dbFilePath_;
#if DEBUG_LOG>=2
	NSLog(@"Using sqlite database at path %@", dbPath);
#endif
	NSAssert([[NSFileManager defaultManager] isReadableFileAtPath:dbPath], ODBsprintf(@"Database file does not exist %@", dbPath));

	NSAssert(database==nil, @"Attempted to start transaction while another is in progress.");
	
	if(sqlite3_open([dbPath UTF8String], &database) == SQLITE_OK) {
#if DEBUG_LOG>=2
		NSLog(@"TRANSACTION BEGIN");
#endif
		sqlite3_exec(database, "BEGIN;", NULL, NULL, NULL);
		if (sqlite3_errcode(database) != SQLITE_DONE && sqlite3_errcode(database)>0)
		{
#if DEBUG_LOG>=1
			NSLog(@"!!!!!!> SQLITE ERROR ===============> %d - %@", sqlite3_errcode(database), [NSString stringWithCString:sqlite3_errmsg(database) encoding:NSUTF8StringEncoding]);
#endif
			return NO;
		}
		return YES;
	}
#if DEBUG_LOG>=1
	NSLog(@"!!!!!!> SQLITE ERROR ===============> Failed to open SQLite database %@;", dbPath);
#endif
	return NO;
}


+ (NSDictionary *)dictionaryForRowData:(sqlite3_stmt *)statement {

    int columns = sqlite3_column_count(statement);
    NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithCapacity:columns];

    for (int i = 0; i<columns; i++) {
        const char *name = sqlite3_column_name(statement, i);

        NSString *columnName = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];

        int type = sqlite3_column_type(statement, i);

        switch (type) {
            case SQLITE_INTEGER:
            {
                int value = sqlite3_column_int(statement, i);
                [result setObject:[NSNumber numberWithInt:value] forKey:columnName];
                break;
            }
            case SQLITE_FLOAT:
            {
                float value = (float)sqlite3_column_double(statement, i);
                [result setObject:[NSNumber numberWithFloat:value] forKey:columnName];
                break;
            }
            case SQLITE_TEXT:
            {
                const char *value = (const char*)sqlite3_column_text(statement, i);
                [result setObject:[NSString stringWithCString:value encoding:NSUTF8StringEncoding] forKey:columnName];
                break;
            }

            case SQLITE_BLOB:
                break;
            case SQLITE_NULL:
                //[result setObject:[NSNull null] forKey:columnName];
                break;

            default:
            {
                const char *value = (const char *)sqlite3_column_text(statement, i);
                [result setObject:[NSString stringWithCString:value encoding:NSUTF8StringEncoding] forKey:columnName];
                break;
            }

        } //end switch
    }
    return [result autorelease];
}

+ (NSArray *)performQueryAndGetResultList:(NSString *)query
{
    return [[self singleton] performQueryAndGetResultList:query];
}

- (NSArray *)performQueryAndGetResultList:(NSString *)query
{
	[lock lock];

	BOOL shouldCommit = NO;
	if (database == nil)
	{
#if DEBUG_LOG>=2
		NSLog(@"======> SQLITE INFO ===============> No transaction started, forcing autocommit");
#endif
        shouldCommit=YES;
		[self begin];
	}
	NSAssert(database!=nil, @"Must begin a transaction first.");
    if (database == nil) return [NSArray new];

#if DEBUG_LOG>=2
	NSLog(@"Performing query:\n\t%@", query);
#endif
	// Setup the SQL Statement and compile it for faster access
	sqlite3_stmt *compiledStatement;
    NSMutableArray* returnData = [NSMutableArray array];

	if(sqlite3_prepare_v2(database, [query UTF8String], -1, &compiledStatement, NULL) == SQLITE_OK)
    {
		// Loop through the results and add them to the feeds array
        while(sqlite3_step(compiledStatement) == SQLITE_ROW)
        {
            [returnData addObject:[SQLiteLibrary dictionaryForRowData:compiledStatement]];
        }

#if DEBUG_LOG>=2
		if (sqlite3_errcode(database) != SQLITE_DONE && sqlite3_errcode(database)>0)
		{
			NSLog(@"!!!!!!> SQLITE ERROR ===============> %d - %@", sqlite3_errcode(database), [NSString stringWithCString:sqlite3_errmsg(database) encoding:NSUTF8StringEncoding]);
		}
#endif

	}
#if DEBUG_LOG>=1
	else
	{
		NSLog(@"!!!!!!> SQLITE ERROR ===============> %d - %@", sqlite3_errcode(database), [NSString stringWithCString:sqlite3_errmsg(database) encoding:NSUTF8StringEncoding]);
	}
#endif
	// Release the compiled statement from memory
	sqlite3_finalize(compiledStatement);
	if (shouldCommit)
		[self commit];

	[lock unlock];
	return returnData;
}

- (int64_t)performQueryInTransaction:(NSString *)query block:(SQLiteBlock)block
{
	[lock lock];

	BOOL shouldCommit = NO;
	if (database == nil)
	{
#if DEBUG_LOG>=2
		NSLog(@"======> SQLITE INFO ===============> No transaction started, forcing autocommit");
#endif
        shouldCommit=YES;
		[self begin];
	}
	NSAssert(database!=nil, @"Must begin a transaction first.");
	if (database == nil) return NO;

	int returnValue = -1;

#if DEBUG_LOG>=2
	NSLog(@"Performing query:\n\t%@", query);
#endif
	// Setup the SQL Statement and compile it for faster access
	sqlite3_stmt *compiledStatement;
	if(sqlite3_prepare_v2(database, [query UTF8String], -1, &compiledStatement, NULL) == SQLITE_OK) {
		// Loop through the results and add them to the feeds array
		[block retain];
		int resultCount = 0;
		while(sqlite3_step(compiledStatement) == SQLITE_ROW) {
			// Read the data from the result row
			resultCount ++;
			if (block!=nil)
				block(compiledStatement);
		}

#if DEBUG_LOG>=2
		if (sqlite3_errcode(database) != SQLITE_DONE && sqlite3_errcode(database)>0)
		{
			NSLog(@"!!!!!!> SQLITE ERROR ===============> %d - %@", sqlite3_errcode(database), [NSString stringWithCString:sqlite3_errmsg(database) encoding:NSUTF8StringEncoding]);
		}
#endif
		if ([[query uppercaseString] hasPrefix:@"INSERT"])
			returnValue = (int)sqlite3_last_insert_rowid(database);
		else if ([[query uppercaseString] hasPrefix:@"SELECT"])
			returnValue = resultCount;
		else
			returnValue = sqlite3_changes(database);

		[block release];
	}
#if DEBUG_LOG>=1
	else
	{
		NSLog(@"!!!!!!> SQLITE ERROR ===============> %d - %@", sqlite3_errcode(database), [NSString stringWithCString:sqlite3_errmsg(database) encoding:NSUTF8StringEncoding]);
	}
#endif
	// Release the compiled statement from memory
	sqlite3_finalize(compiledStatement);
	if (shouldCommit)
		[self commit];

	[lock unlock];
	return returnValue;
}

+ (BOOL)commit
{
	return [[self singleton] commit];
}

- (BOOL)commit
{
    [lock lock];

    if (database == nil)
    {
        [lock unlock];
        return NO;
    }

	sqlite3_exec(database, "COMMIT;", NULL, NULL, NULL);
	BOOL success = YES;
	if (sqlite3_errcode(database) != SQLITE_DONE && sqlite3_errcode(database)>0)
	{
#if DEBUG_LOG>=1
		NSLog(@"!!!!!!> SQLITE ERROR ===============> %d - %@", sqlite3_errcode(database), [NSString stringWithCString:sqlite3_errmsg(database) encoding:NSUTF8StringEncoding]);
#endif
        success=NO;
	}
#if DEBUG_LOG>=2
	NSLog(@"TRANSACTION COMMIT");
#endif
	sqlite3_close(database);
	database = nil;

    [lock unlock];
    [lock unlock];
	return success;
}

+ (int64_t)performQuery:(NSString *)query block:(SQLiteBlock)block
{
	return [[self singleton] performQueryInTransaction:query block:block];
}

- (void)setupDatabaseAndForceReset:(BOOL)forceReset
{
    NSAssert(dbFilePath_!=nil, @"dbFilePath must be set!");

    NSString* defaultDB = [[NSBundle mainBundle]pathForResource:@"data_skeleton" ofType:@"sqlite3"];
    NSString* appFile = dbFilePath_;
    BOOL exists = [[NSFileManager defaultManager]fileExistsAtPath:appFile];
    if (exists && forceReset)
        [[NSFileManager defaultManager] removeItemAtPath:appFile error:nil];

    if (!exists || forceReset)
        [[NSFileManager defaultManager]copyItemAtPath:defaultDB toPath:appFile error:nil];
}

+ (void)setupDatabaseAndForceReset:(BOOL)forceReset
{
    [[self singleton] setupDatabaseAndForceReset:forceReset];
}

@end
