#include "greeter.hpp"
#include <iostream>

Greeter::Greeter(std::string name) : m_name(std::move(name)) {}

void Greeter::greet() const {
    std::cout << "Hello from modern C++20 in " << m_name << "!\n";
}
