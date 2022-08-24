# C++ Project Template

This is a simple C++ project template with a bunch of sane defaults.
I found myself re-creating these things every time I needed to quickly spin up a project.
This template solves that.

It includes:
* A basic cmake file and a `main.cc` that prints Hello World
* gtest for testing
* clang-format and clang-tidy with a bunch of default option
* The `add_ak_test` macro to make adding a test easier
* The `ak_source_file_checks` macro to run formatting and clang-tidy checks over files. This can be extended easily to
  add checks for licenses, copyright headers etc)

