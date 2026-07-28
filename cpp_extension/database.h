#ifndef DATABASE_H
#define DATABASE_H

#include <sqlite3.h>

struct PlayerData
{
    int coins = 0;
    int experience = 0;
    int highest_wave = 0;
};

class Database {
public:
    sqlite3* db = nullptr;

    bool open();
    void close();
    void create_tables();

    bool save_player_data(int user_id, const PlayerData& data);
    bool load_player_data(int user_id, PlayerData& data);
};

#endif