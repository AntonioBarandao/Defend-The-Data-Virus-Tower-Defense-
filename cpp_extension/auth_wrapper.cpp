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

    if(success) {
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
    current_user_id = -1;
    current_username = "";
}