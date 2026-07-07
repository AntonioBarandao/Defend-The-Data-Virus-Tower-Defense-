#include "auth.h"
#include <iostream>

Auth::Auth(Database* db) {
    database = db;
}

bool Auth::register_user(std::string username,
                         std::string password) {

    std::cout << "\n========== REGISTER ==========" << std::endl;
    std::cout << "Username: " << username << std::endl;
    std::cout << "Password: " << password << std::endl;

    const char* sql =
        "INSERT INTO users(username, password) VALUES(?, ?);";

    sqlite3_stmt* stmt;

    int rc = sqlite3_prepare_v2(
        database->db,
        sql,
        -1,
        &stmt,
        nullptr
    );

    if (rc != SQLITE_OK) {
        std::cout << "Prepare failed!" << std::endl;
        std::cout << "SQLite Error Code: " << rc << std::endl;
        std::cout << "SQLite Error: "
                  << sqlite3_errmsg(database->db)
                  << std::endl;
        return false;
    }

    sqlite3_bind_text(stmt, 1, username.c_str(), -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 2, password.c_str(), -1, SQLITE_TRANSIENT);

    rc = sqlite3_step(stmt);

    std::cout << "sqlite3_step() returned: " << rc << std::endl;

    if (rc != SQLITE_DONE) {
        std::cout << "Registration FAILED!" << std::endl;
        std::cout << "SQLite Error Code: " << rc << std::endl;
        std::cout << "SQLite Error: "
                  << sqlite3_errmsg(database->db)
                  << std::endl;
        std::cout << "==============================" << std::endl;

        sqlite3_finalize(stmt);
        return false;
    }

    std::cout << "Registration SUCCESS!" << std::endl;
    std::cout << "==============================" << std::endl;

    sqlite3_finalize(stmt);
    return true;
}

bool Auth::login(std::string username,
                 std::string password) {

    std::cout << "\n========== LOGIN ==========" << std::endl;
    std::cout << "Username: " << username << std::endl;

    const char* sql =
        "SELECT * FROM users WHERE username=? AND password=?;";

    sqlite3_stmt* stmt;

    int rc = sqlite3_prepare_v2(
        database->db,
        sql,
        -1,
        &stmt,
        nullptr
    );

    if (rc != SQLITE_OK) {
        std::cout << "Prepare failed!" << std::endl;
        std::cout << "SQLite Error Code: " << rc << std::endl;
        std::cout << "SQLite Error: "
                  << sqlite3_errmsg(database->db)
                  << std::endl;
        return false;
    }

    sqlite3_bind_text(stmt, 1, username.c_str(), -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 2, password.c_str(), -1, SQLITE_TRANSIENT);

    rc = sqlite3_step(stmt);

    bool success = (rc == SQLITE_ROW);

    if (success) {
        std::cout << "Login SUCCESS!" << std::endl;
    } else {
        std::cout << "Login FAILED!" << std::endl;
        std::cout << "sqlite3_step() returned: " << rc << std::endl;
        std::cout << "SQLite Error: "
                  << sqlite3_errmsg(database->db)
                  << std::endl;
    }

    std::cout << "===========================" << std::endl;

    sqlite3_finalize(stmt);

    return success;
}