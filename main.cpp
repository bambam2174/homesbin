//usr/bin/clang++ -O3 -std=c++11 "$0" && ./a.out && rm a.out; exit
#include <iostream>
int main() {
    for (auto i: {1, 2, 3})
        std::cout << i << std::endl;
    return 0;
}


