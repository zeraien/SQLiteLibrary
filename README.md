This is a very simple SQLite wrapper for Mac OS X and iOS development.

It's not thread safe and is a singleton, so it allows for a single database connection.

It has support for transactions and uses blocks heavily.

## Data skeleton and data locations

Before using the library you have to set the name of your preferred database file and it's location.


    # Store database data in the cache
    [SQLiteLibrary setDatabaseFileInCache:@"dbstuff.sqlite"];
     
    # Store database data in the persistent documents folder
    [SQLiteLibrary setDatabaseFileInCache:@"dbstuff.sqlite"];

After setting the file name, the code below will copy the file **data_skeleton.sqlite3** to the file you specified above.
Note that this will **NOT** override the file, **UNLESS** you specify *true* as the **ForceReset** parameter.

    [SQLiteLibrary setupDatabaseAndForceReset:NO];

### setDatabaseFileInCache 

The *cache* location will store the database in a cache folder and this folder can be deleted at any time
when the application is not running. It is also not backed up.

Use this for databases that store temporary data that you will not need to store between application launches.

### setDatabaseFileInDocuments

The *documents* location will store the database in the user's Documents folder. This folder is persistent
and will not be deleted unless the user uninstalls the iOS application or manually deletes the file on Mac.

Use this for databases that store persistent data such as user profiles or game highscores.

## Logging

Log messages are output based on your setting of *DEBUG_LOG* preprocessor macro.

* 1 - outputs basic messages and errors
* 2 - outputs every query and lots of other data

## Typical usage scenario

    [SQLiteLibrary setDatabaseFileInCache:@"dbstuff.sqlite"];
    [SQLiteLibrary setupDatabaseAndForceReset:NO];
    [SQLiteLibrary begin];
    
    # Insert query
    [SQLiteLibrary performQuery:@"INSERT INTO tablename (bar, foo) VALUES(2,3)" block:nil];

    # Select query
    # The block will be called once for every row returned from the query
    [SQLiteLibrary performQuery:@"SELECT foo, bar FROM tablename" block:^(sqlite3_stmt *rowData) {
        NSString* stringValue = sqlite3_column_nsstring(rowData, 0);
        int intValue = sqlite3_column_int(rowData, 1);
    }];
    
## Using transactions

By default every query is performed in it's own transaction, however if you are performing lots
of insert queries using transactions increases performance quite a bit.

    [SQLiteLibrary begin];
    [SQLiteLibrary performQuery:@"INSERT INTO tablename (bar, foo) VALUES(22,3)" block:nil];
    [SQLiteLibrary performQuery:@"INSERT INTO tablename (bar, foo) VALUES(252,234542)" block:nil];
    [SQLiteLibrary performQuery:@"INSERT INTO tablename (bar, foo) VALUES(252,5253)" block:nil];
    [SQLiteLibrary performQuery:@"INSERT INTO tablename (bar, foo) VALUES(2222,2523)" block:nil];
    [SQLiteLibrary performQuery:@"INSERT INTO tablename (bar, foo) VALUES(512,352)" block:nil];
    [SQLiteLibrary commit];


## sqlite3_column_nsstring

I've written a custom macro *sqlite3_column_nsstring* for extracting NSString objects from SQLite c strings.