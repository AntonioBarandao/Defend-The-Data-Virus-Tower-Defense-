#ifndef AUTH_WRAPPER_H
#define AUTH_WRAPPER_H

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/dictionary.hpp>

#include "database.h"
#include "auth.h"

using namespace godot;

class AuthWrapper : public RefCounted {
    GDCLASS(AuthWrapper, RefCounted);

private:
    Database db;
    Auth* auth;

    godot::String current_username = "";

protected:
    static void _bind_methods();

public:
    AuthWrapper();
    ~AuthWrapper();

    // Authentication
    bool login(String username, String password);
    bool register_user(String username, String password);
    void logout();

    // Save System
    bool save_game(int coins,
                   int experience,
                   int highest_wave);

    Dictionary load_game();

    // Current user
    int get_current_user_id() const;
};

#endif