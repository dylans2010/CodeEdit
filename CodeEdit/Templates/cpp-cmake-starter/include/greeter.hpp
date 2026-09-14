#pragma once
#include <string>

class Greeter {
public:
    explicit Greeter(std::string name);
    void greet() const;
private:
    std::string m_name;
};
