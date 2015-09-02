void function(int x) {
    int a = 0;
    int *y = &a + 4;
    *y += 1;
}

void main() {
    int x;
    x = 5;
    function(x);
    x = 8;
    printf("%d\n", x);
}
