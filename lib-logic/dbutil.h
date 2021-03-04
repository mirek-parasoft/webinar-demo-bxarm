typedef struct Person {
    char* name;
    int personalId;
    char* reference;
    int salary;
    int daysWorkedInPassedMonth;
} Person;

Person* retrievePersonFromDB(int id);


int dummy(int a, int b);