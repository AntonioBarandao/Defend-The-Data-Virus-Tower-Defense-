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
    
    const  char* Player_sql = 
       "CREATE TABLE IF NOT EXISTS player_data("
       "user_id INTEGER PRIMARY KEY,"
       "coins INTEGER DEFAULT 0,"
       "experience INTEGER DEFAULT 0,"
       "highest_wave INTEGER DEFAULT 0,"
       "FOREIGN KEY(user_id) REFERENCES users(id));";

    char* errMsg = nullptr;

    int rc = sqlite3_exec(
        db,
        sql,
        nullptr,
        nullptr,
        &errMsg
    );

      if (rc != SQLITE_OK) {

        std::cout << "Create users table failed: "
                  << errMsg
                  << std::endl;

        sqlite3_free(errMsg);
        errMsg = nullptr;
    }
    else {
        std::cout << "Users table ready." << std::endl;
    }

    // Create player_data table
    rc = sqlite3_exec(
        db,
        Player_sql,
        nullptr,
        nullptr,
        &errMsg
    );

    if (rc != SQLITE_OK) {

        std::cout << "Create player_data table failed: "
                  << errMsg
                  << std::endl;

        sqlite3_free(errMsg);
        errMsg = nullptr;
    }
    else {
        std::cout << "Player data table ready." << std::endl;
    }
}