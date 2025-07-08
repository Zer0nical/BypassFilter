#include <iostream>

int main() {
    std::cout << "\033[33m";
    std::cout << R"(
     _____________________________________________
    |                                             |
    |      )===(                                  |
    |      |###|    B Y P A S S   F I L T E R     |
    |      |###|       -= Security Tool =-        |
    |      )===(                                  |
    |                                             |
    |      * * *  Penetration Testing             |
    |       * *   Vulnerability Scanning          |
    |        *    Security Research               |
    |                                             |
    |_____________________________________________|
    )" << std::endl;
    std::cout << "\033[0m";
    return 0;
}