#include "auth_wrapper.h"

void AuthWrapper::_bind_methods() {
    ClassDB::bind_method(
        D_METHOD("login", "username", "password"),
        &AuthWrapper::login
    );

    ClassDB::bind_method(
        D_METHOD("register_user", "username", "password"),
        &AuthWrapper::register_user
    );

    ClassDB::bind_method(
        D_METHOD("logout"),
        &AuthWrapper::logout
    );

    ClassDB::bind_method(
        D_METHOD("save_game", "coins", "experience", "highest_wave"),
        &AuthWrapper::save_game
    );

    ClassDB::bind_method(
        D_METHOD("load_game"),
        &AuthWrapper::load_game
    );

    ClassDB::bind_method(
        D_METHOD("get_current_user_id"),
        &AuthWrapper::get_current_user_id
    );
}

AuthWrapper::AuthWrapper() {
    db.open();
    db.create_tables();

    auth = new Auth(&db);
}

AuthWrapper::~AuthWrapper() {
    delete auth;
    db.close();
}

bool AuthWrapper::login(String username, String password) {

    bool success = auth->login(
        username.utf8().get_data(),
        password.utf8().get_data()
    );

    if (success) {
        current_username = username;
    }

    return success;
}

bool AuthWrapper::register_user(String username, String password) {

    return auth->register_user(
        username.utf8().get_data(),
        password.utf8().get_data()
    );
}

void AuthWrapper::logout() {

    current_username = "";
}

bool AuthWrapper::save_game(int coins,
                            int experience,
                            int highest_wave)
{
    int user_id = auth->get_current_user_id();

    if (user_id == -1)
        return false;

    PlayerData data;

    data.coins = coins;
    data.experience = experience;
    data.highest_wave = highest_wave;

    return db.save_player_data(user_id, data);
}

Dictionary AuthWrapper::load_game()
{
    Dictionary save;

    int user_id = auth->get_current_user_id();

    if (user_id == -1)
        return save;

    PlayerData data;

    if (db.load_player_data(user_id, data))
    {
        save["coins"] = data.coins;
        save["experience"] = data.experience;
        save["highest_wave"] = data.highest_wave;
    }

    return save;
}

int AuthWrapper::get_current_user_id() const
{
    return auth->get_current_user_id();
}