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

    const char* Player_sql =
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

bool Database::save_player_data(int user_id, const PlayerData& data)
{
    const char* sql =
        "INSERT INTO player_data "
        "(user_id, coins, experience, highest_wave) "
        "VALUES (?, ?, ?, ?) "
        "ON CONFLICT(user_id) DO UPDATE SET "
        "coins = excluded.coins, "
        "experience = excluded.experience, "
        "highest_wave = excluded.highest_wave;";

    sqlite3_stmt* stmt = nullptr;

    if (sqlite3_prepare_v2(db, sql, -1, &stmt, nullptr) != SQLITE_OK)
    {
        std::cout << "Prepare failed: "
                  << sqlite3_errmsg(db)
                  << std::endl;
        return false;
    }

    sqlite3_bind_int(stmt, 1, user_id);
    sqlite3_bind_int(stmt, 2, data.coins);
    sqlite3_bind_int(stmt, 3, data.experience);
    sqlite3_bind_int(stmt, 4, data.highest_wave);

    bool success = (sqlite3_step(stmt) == SQLITE_DONE);

    sqlite3_finalize(stmt);

    return success;
}

bool Database::load_player_data(int user_id, PlayerData& data)
{
    const char* sql =
        "SELECT coins, experience, highest_wave "
        "FROM player_data "
        "WHERE user_id = ?;";

    sqlite3_stmt* stmt = nullptr;

    if (sqlite3_prepare_v2(db, sql, -1, &stmt, nullptr) != SQLITE_OK)
    {
        std::cout << "Prepare failed: "
                  << sqlite3_errmsg(db)
                  << std::endl;
        return false;
    }

    sqlite3_bind_int(stmt, 1, user_id);

    if (sqlite3_step(stmt) == SQLITE_ROW)
    {
        data.coins = sqlite3_column_int(stmt, 0);
        data.experience = sqlite3_column_int(stmt, 1);
        data.highest_wave = sqlite3_column_int(stmt, 2);

        sqlite3_finalize(stmt);
        return true;
    }

    sqlite3_finalize(stmt);
    return false;
}