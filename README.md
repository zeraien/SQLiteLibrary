This is a very simple SQLite wrapper for Mac OS X and iOS development.

It has support for transactions and uses blocks heavily.

Still working on documentation, but here is a use example:

## Typical usage scenario

    [SQLiteLibrary setDatabaseFileInCache:@"dbstuff.sqlite"];
    [SQLiteLibrary setupDatabaseAndForceReset:NO];
    [SQLiteLibrary begin];
    
    # Insert query
    [SQLiteLibrary performQuery:@"INSERT INTO tablename (bar, foo) VALUES(2,3)" block:nil];

    # Select query
    [SQLiteLibrary performQuery:@"SELECT foo, bar FROM tablename" block:^(sqlite3_stmt *rowData) {
        NSString* stringValue = sqlite3_column_nsstring(rowData, 0);
        int intValue = sqlite3_column_int(rowData, 1);
    }];

## sqlite3_column_nsstring

I've written a custom macro *sqlite3_column_nsstring* for extracting NSString objects from SQLite c strings.