#include <stdio.h>
#include <sqlite3.h>

int main(void) {
    sqlite3 *db;
    if (sqlite3_open(":memory:", &db) == SQLITE_OK) {
        printf("{{PROJECT_NAME}}: In-memory SQLite database initialized.\n");
        sqlite3_close(db);
    }
    return 0;
}
