#include "greeter.hpp"

int main() {
    Greeter greeter("{{PROJECT_NAME}}");
    greeter.greet();
    return 0;
}
