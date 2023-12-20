class T
{
    int x;
 
    void foo()
    {
        x = 6;       // same as this->x = 6;
        this->x = 5; // explicit use of this->
    }
 
    void foo() const
    {
//        x = 7; // Error: *this is constant
    }
 
    void foo(int x) // parameter x shadows the member with the same name
    {
        this->x = x; // unqualified x refers to the parameter
                     // 'this->' required for disambiguation
    }
 
    int y;
    T(int x) : x(x), // uses parameter x to initialize member x
               y(this->x) // uses member x to initialize member y
    {}
 
    T& operator= ( const T& b )
    {
        x = b.x;
        return *this; // many overloaded operators return *this
    }
};
 
class Outer {
//    int a[sizeof(*this)]; // error: not inside a member function
    unsigned int sz = sizeof(*this); // OK: in default member initializer
    void f() {
        int sizeOfOuter = sizeof(*this);
        int b[sizeof(*this)]; // OK
        struct Inner {
            //int c[sizeof(*this)]; // error: not inside a member function of Inner
            //int c[sizeOfOuter]; // error: not inside a member function of Inner
            int c[16]; // error: not inside a member function of Inner
        };
    }
};

