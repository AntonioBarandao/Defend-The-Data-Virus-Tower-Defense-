#include "database.h"
#include <iostream>
#include <filesystem>

bool Database::open() {

    std::cout << "Current directory: "
              << std::filesystem::current_path()
              << std::endl;

    int rc = sqlite3_open("game.db", &db);

    if (rc != SQLITE_OK) {
        

        std::cout << "Cannot open database: "
                  << sqlite3_errmsg(db)
                  << std::endl;

        return false;
        
    }

    std::cout << "Database opened successfully.\n";

    return true;
}

void Database::close() {

    if (db != nullptr) {
        sqlite3_close(db);
        db = nullptr;
    }
}

void Database::create_tables() {

    const char* sql =
        "CREATE TABLE IF NOT EXISTS users("
        "id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "username TEXT UNIQUE,"
        "password TEXT);";

    char* errMsg = nullptr;

    int rc = sqlite3_exec(
        db,
        sql,
        nullptr,
        nullptr,
        &errMsg
    );

    if (rc != SQLITE_OK) {

        std::cout << "Create table failed: "
                  << errMsg
                  << std::endl;

        sqlite3_free(errMsg);
    }
}