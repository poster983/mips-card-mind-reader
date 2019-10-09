#include <iostream>
#include <math.h>
#include <time.h>
#include <stdlib.h>

using namespace std;

// 2^ORDER is the size of the list we are searchin in
const int ORDER = 6;

int main()
{
    srand(time(NULL));

    // Final value
    int number = 0;

    // max is = sll output, 1, order
    int max = 1 << ORDER;
    // helper variable, not necessary for assembly implementation
    int section;
    // row counter integer
    int rowCount;
    // Store user response
    char response;
    // Start with mask 000001, bit shift left 1 each iteration (seen at end of loop)
    int mask;
    int history = 0;

    // loop until i >= order, increment by 1
    for (int i = 0; i < ORDER; i++)
    {
        do
        {
            mask = 1;
            int randN = rand() % 6;
            // Shift mask left random bit between 0 and 5
            mask = mask << randN;
        } while ((mask | history) == history);
        history = history | mask;
        cout << "Hist: " << history << " Mask: " << mask << endl;
        // reset row counter to 0 for new section
        rowCount = 0;
        // loop while n < max
        for (int n = 0; n < max; n++)
        {
            // Helper variable
            // section = n / orderWidth;
            // If (n AND mask) == mask
            if ((n & mask) == mask)
            {
                // Print number and tab character
                cout << n << "\t";
                // Increment row counter
                rowCount++;
                // If (row counter > row width)
                if (rowCount >= 8)
                {
                    // set row counter to 0
                    rowCount = 0;
                    // print carraige return
                    cout << endl;
                }
            }
        }
        // prompt user input
        cout << "Is your number in this list?" << endl << "'Y' for yes, anything else for no" << endl;
        cin >> response;
        // compare user input to target input
        // this will be the last byte in the first word in the input memory area
        // [little endian]
        if (response == 'Y' || response == 'y')
        {
            // (number OR mask) = number
            number = number | mask;
        }
        
        
        
    }
    // print number
    cout << "Your number is: " << number << endl;

    return number;
}

// Run program: Ctrl + F5 or Debug > Start Without Debugging menu
// Debug program: F5 or Debug > Start Debugging menu

// Tips for Getting Started: 
//   1. Use the Solution Explorer window to add/manage files
//   2. Use the Team Explorer window to connect to source control
//   3. Use the Output window to see build output and other messages
//   4. Use the Error List window to view errors
//   5. Go to Project > Add New Item to create new code files, or Project > Add Existing Item to add existing code files to the project
//   6. In the future, to open this project again, go to File > Open > Project and select the .sln file
