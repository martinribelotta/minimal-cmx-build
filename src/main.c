volatile int n;
volatile int p;
volatile int k = 20;

int main()
{
    for (n=0; n<k; n++) {
        p = n;
    }
    return 0;
}
