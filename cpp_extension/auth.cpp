#include "auth.h"
#include <iostream>

Auth::Auth(Database* db) {
    database = db;
}

bool Auth::register_user(std::string username,
                         std::string password) {

    std::cout << "\n========== REGISTER ==========" << std::endl;
    std::cout << "Username: " << username << std::endl;

    const char* sql =
        "INSERT INTO users(username, password) VALUES(?, ?);";

    sqlite3_stmt* stmt = nullptr;

    int rc = sqlite3_prepare_v2(
        database->db,
        sql,
        -1,
        &stmt,
        nullptr
    );

    if (rc != SQLITE_OK) {
        std::cout << "Prepare failed!\n";
        std::cout << sqlite3_errmsg(database->db) << std::endl;
        return false;
    }

    sqlite3_bind_text(stmt, 1, username.c_str(), -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 2, password.c_str(), -1, SQLITE_TRANSIENT);

    rc = sqlite3_step(stmt);

    sqlite3_finalize(stmt);

    if (rc != SQLITE_DONE) {
        std::cout << "Registration FAILED!" << std::endl;
        return false;
    }

    std::cout << "Registration SUCCESS!" << std::endl;

    return true;
}

bool Auth::login(std::string username,
                 std::string password) {

    std::cout << "\n========== LOGIN ==========" << std::endl;
    std::cout << "Username: " << username << std::endl;

    const char* sql =
        "SELECT id FROM users WHERE username=? AND password=?;";

    sqlite3_stmt* stmt = nullptr;

    int rc = sqlite3_prepare_v2(
        database->db,
        sql,
        -1,
        &stmt,
        nullptr
    );

    if (rc != SQLITE_OK) {
        std::cout << "Prepare failed!\n";
        std::cout << sqlite3_errmsg(database->db) << std::endl;
        return false;
    }

    sqlite3_bind_text(stmt, 1, username.c_str(), -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(stmt, 2, password.c_str(), -1, SQLITE_TRANSIENT);

    rc = sqlite3_step(stmt);

    if (rc == SQLITE_ROW)
    {
        current_user_id = sqlite3_column_int(stmt, 0);

        std::cout << "Login SUCCESS!" << std::endl;
        std::cout << "User ID: " << current_user_id << std::endl;

        sqlite3_finalize(stmt);
        return true;
    }

    sqlite3_finalize(stmt);

    current_user_id = -1;

    std::cout << "Login FAILED!" << std::endl;

    return false;
}

int Auth::get_current_user_id() const
{
    return current_user_id;
}