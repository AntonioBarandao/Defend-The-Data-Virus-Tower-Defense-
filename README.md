Defend The Data - Virus Tower Defense

Overview

Defend The Data is a cybersecurity-themed tower defense game built with the Godot Engine. Players defend a computer network against waves of viruses while managing resources, upgrading defenses, and tracking their progress through a secure account system. Players are given a cybersecurity or networking questions and if they are
right are given money "Cyberbucks" to upgrade and place towers.

The project combines game development with software engineering concepts including database management, user authentication, and C++ integration with Godot.

---

Features

- User registration and login system
- SQLite database for account storage
- Cyberbucks currency system
- Experience tracking
- Highest wave tracking
- Automatic game saving
- Sandbox mode
- Normal gameplay mode

---

Technologies Used

Engine
- Godot 4

Programming Languages
- GDScript
- C++

Database
- SQLite3

Libraries
- Godot C++ GDExtension
- SQLite3

Development Tools
- Visual Studio 2022
- CMake
- Git
- GitHub
- Xogot

---

Authentication System

The game uses a custom authentication system written in C++.

Users can:

- Register new accounts
- Login with existing accounts
- Store credentials inside SQLite
- Load saved player progress after login

Database

The game uses SQLite to store both user accounts and player progress.

Users Table

| Column | Description |
|---------|-------------|
| id | User ID |
| username | Unique username |
| password | User password |

Player Data Table

| Column | Description |
|---------|-------------|
| user_id | Linked account |
| coins | Cyberbucks |
| experience | XP earned |
| highest_wave | Best wave completed |

---

Save System

Player progress is automatically saved.

Information saved includes:

- Cyberbucks
- Experience
- Highest Wave

Each player's progress is tied to their account through their unique User ID.

---

Cyberbucks

Cyberbucks are the primary in-game currency.

Players earn Cyberbucks by:

- Answering questions
- Defeating enemies

Cyberbucks can later be used for:

- Purchasing towers
- Upgrading defenses

---

Gameplay

Players defend a computer network against incoming malware.

Enemies attempt to reach critical servers while the player strategically places defensive towers.

As waves increase:

- More enemies spawn
- Enemy difficulty increases
- Rewards become larger

---

Building the Project

Requirements

- Godot 4
- Visual Studio 2022
- CMake
- SQLite3
- Godot C++

Build Steps

1. Clone the repository

```
git clone https://github.com/AntonioBarandao/Defend-The-Data-Virus-Tower-Defense-.git
```

2. Generate the CMake project

```
cmake -B build
```

3. Build the extension

```
cmake --build build --config Debug
```

4. Open the project in Godot.

---

Future Improvements

- Password hashing
- Password reset system
- Leaderboard
- Achievement system
- Additional tower types
- More enemy variants
- Difficulty settings
- Cosmetics

---

Learning Objectives

This project demonstrates experience with:

- Object-Oriented Programming
- Database Design
- SQLite
- Godot Engine
- GDScript
- C++
- GDExtensions
- Authentication Systems
- Save Systems
- UI Design
- Git Version Control
- Software Architecture

---

Authors

Jonathan Hua-Phan, Tyler Foskitt, Antonio Barandao
