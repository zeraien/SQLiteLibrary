/*
 * Copyright 2012 Dmitri Fedortchenko
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#import <Foundation/Foundation.h>
#import <sqlite3.h>

#define sqlite_now_epoch @"strftime('%s','now')"
#ifdef __cplusplus
extern "C" {
#endif

    NSString* sqlite3_column_nsstring(sqlite3_stmt* statement, int column);

#ifdef __cplusplus
}
#endif

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

- (BOOL)verifyDatabaseFile;

+ (BOOL)verifyDatabaseFile;


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
