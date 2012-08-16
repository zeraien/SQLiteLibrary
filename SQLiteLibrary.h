//
//  Created by zeraien on 11/11/11.
//
//


#import <Foundation/Foundation.h>
#import <sqlite3.h>

typedef void (^SQLiteBlock)(sqlite3_stmt *compiledStatement);

@interface SQLiteLibrary : NSObject
{
	sqlite3 *database;
	NSRecursiveLock *lock;
}
+ (SQLiteLibrary *)singleton;

+ (void)setDatabaseFile:(NSString *)dbFilePath;

+ (void)setDatabaseFileInDocuments:(NSString *)dbFilename;

+ (void)setDatabaseFileInCache:(NSString *)dbFilename;


/**
* Begin transaction (singleton edition)
*/
+ (BOOL)begin;

+ (NSDictionary *)dictionaryForRowData:(sqlite3_stmt *)statement;

+ (NSArray*)performQueryAndGetResultList:(NSString*)query;


/**
* Commit transaction (singleton edition)
*/
+ (BOOL)commit;

/**
* See +performQuery:block:
*/
- (int64_t)performQueryInTransaction:(NSString *)query block:(SQLiteBlock)block;

/** Perform an SQL query. Works with any SQL query. (singleton edition)
* If no transaction has been started, the method will start a new transaction and auto-commit at the end of the query.
*
* @param query SQL query
* @param block Block with SQL result
* @return Returns different values depending on query: INSERT returns the id of the inserted row, UPDATE returns the number of affected rows, SELECT returns number of found rows
* */
+ (int64_t)performQuery:(NSString *)query block:(SQLiteBlock)block;

/**
* Copy database skeleton to user's documents directory.
* @param forceReset if True, overwrite existing database in user's documents directory
*/
+ (void)setupDatabaseAndForceReset:(BOOL)forceReset;

/**
* Begin transaction
*/
- (BOOL)begin;


/**
* Commit transaction
*/
- (BOOL)commit;


@end
