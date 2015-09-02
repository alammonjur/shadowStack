#include <string.h>

int func1();
int func1_nested();
int func2();
int func3();

int main(int argc, char* argv[])
{
    func1();
    func2();
    func3();
    return 0;
}

int func1()
{
    func1_nested();

    int dummy[2] = {0,0};
    int *ret = dummy; // Pointing to the address of dummy
    ret += 4; // Locateing the return address in the stack
    *ret += 4; // Make a skip to the next instruction
    return 0;
}

int func1_nested()
{
    return 0;
}

int func2()
{
    return 0;
}

int func3()
{
    return 0;
}

