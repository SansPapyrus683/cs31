#include <iostream>
#include <iomanip>
#include <string>
#include <limits>
#include <algorithm>

using namespace std;

int main() {
    string prop;
    cout << "Identification: ";
    getline(cin, prop);
    if (prop.empty()) {
        cout << "---\nYou must enter a property identification." << endl;
        return 0;
    }
    
    float amt;
    cout << "Overstated amount (in millions): ";
    cin >> amt;
    if (amt <= 0) {
        cout << "---\nThe overstated amount must be positive." << endl;
        return 0;
    }

    string location;
    cout << "Location: ";
    cin.ignore(numeric_limits<streamsize>::max(), '\n');
    getline(cin, location);
    if (location.empty()) {
        cout << "---\nYou must enter a location." << endl;
        return 0;
    }

    float fine = 0;
    float remaining_amt = amt;
    constexpr float THRESH1 = 60;
    constexpr float THRESH2 = 90;

    if (remaining_amt >= THRESH1 + THRESH2) {
        float exceeded = remaining_amt - (THRESH1 + THRESH2);
        fine += exceeded * .21;
        remaining_amt -= exceeded;
    }
    if (remaining_amt >= THRESH1) {
        float rate = location == "florida" || location == "new york" ? .18 : .153;
        float exceeded = remaining_amt - THRESH1;
        fine += exceeded * rate;
        remaining_amt -= exceeded;
    }

    fine += remaining_amt * .1111;

    cout << "---" << endl;

    cout << fixed << setprecision(3);
    cout << "The fine for " << prop << " is $" << fine << " million." << endl;
}
