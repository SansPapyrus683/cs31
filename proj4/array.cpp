#include <iostream>
#include <string>
#include <cassert>

using namespace std;

/** Swaps the elements at indexes x and y in the array. */
void swap(string a[], int x, int y) {
    string tmp = a[x];
    a[x] = a[y];
    a[y] = tmp;
}

/** Prints out an array for debugging purposes. */
void print(string a[], int n) {
    cout << '[';
    for (int i = 0; i < n - 1; i++) {
        cout << a[i] << ", ";
    }
    cout << a[n - 1] << ']' << endl;
}

int reduplicate(string a[], int n) {
    if (n < 0) {
        return -1;
    }
    for (int i = 0; i < n; i++) {
        a[i] += a[i];
    }
    return n;
}

int locate(const string a[], int n, string target) {
    for (int i = 0; i < n; i++) {
        if (a[i] == target) {
            return i;  // return index if value is equal to target
        }
    }
    return -1;
}

int locationOfMax(const string a[], int n) {
    if (n <= 0) {
        return -1;
    }

    // these store the largest value's index and value respectively
    int maxInd = 0;
    string max = a[0];
    for (int i = 1; i < n; i++) {
        if (a[i] > max) {
            max = a[i];  // update max and its position
            maxInd = i;
        }
    }
    return maxInd;
}

int circleLeft(string a[], int n, int pos) {
    if (n < 0 || pos < 0 || pos >= n) {
        return -1;
    }
    string tmp = a[pos];  // store the shifted-out value
    for (int i = pos; i < n - 1; i++) {
        a[i] = a[i + 1];
    }
    a[n - 1] = tmp;  // and put it back here
    return pos;
}

int enumerateRuns(const string a[], int n) {
    if (n < 0) {
        return -1;
    }
    if (n == 0) {
        return 0;
    }
    int runs = 1;  // there's always going to be at least 1 run
    for (int i = 1; i < n; i++) {
        if (a[i] != a[i - 1]) {
            runs++;  // a change in values means a new run
        }
    }
    return runs;
}

int flip(string a[], int n) {
    if (n < 0) {
        return -1;
    }
    // we only have to go up to n/2!
    for (int i = 0; i < n / 2; i++) {
        swap(a[i], a[n - 1 - i]);
    }
    return n;
}

int locateDifference(const string a1[], int n1, const string a2[], int n2) {
    if (n1 < 0 || n2 < 0) {
        return -1;
    }
    // only go up to the smaller array index
    int min = n1 < n2 ? n1 : n2;
    for (int i = 0; i < min; i++) {
        if (a1[i] != a2[i]) {
            return i;
        }
    }
    return min;  // return the array length if it's the same till one runs out
}

int subsequence(const string a1[], int n1, const string a2[], int n2) {
    if (n1 < 0 || n2 < 0 || n2 > n1) {
        return -1;
    }
    // try all possible starts
    for (int i = 0; i < n1 - n2; i++) {
        bool valid = true;
        // check if this start is valid for all subsequences
        for (int j = i; j < i + n2; j++) {
            if (a1[j] != a2[j - i]) {
                valid = false;
                break;
            }
        }
        if (valid) {
            return i;
        }
    }
    return -1;
}

int locateAny(const string a1[], int n1, const string a2[], int n2) {
    for (int i = 0; i < n1; i++) {
        // check all elements in a2 and see if any of them match a1[i]
        for (int j = 0; j < n2; j++) {
            if (a1[i] == a2[j]) {
                return i;
            }
        }
    }
    return -1;
}

int divide(string a[], int n, string divider) {
    if (n < 0) {
        return false;
    }
    bool divided = false;
    /*
     * basically bubble sort- while it still seems there's elements out of order,
     * iterate through the array and swap any inversions
     */
    while (!divided) {
        divided = true;
        for (int i = 0; i < n - 1; i++) {
            bool firstLt = a[i] < divider;
            bool secondLt = a[i + 1] < divider;
            if (!firstLt && secondLt) {
                swap(a[i], a[i + 1]);
                divided = false;
            }
        }
    }

    for (int i = 0; i < n; i++) {
        if (a[i] >= divider) {
            return i;
        }
    }
    return n;
}

int main() {
    string h[] = { "nikki", "ron", "asa", "vivek", "", "chris", "donald" };
    assert(locate(h, 7, "chris") == 5);
    assert(locate(h, 7, "asa") == 2);
    assert(locate(h, 2, "asa") == -1);
    assert(locationOfMax(h, 7) == 3);

    string g[] = { "nikki", "ron", "chris", "tim" };
    assert(locateDifference(h, 4, g, 4) == 2);
    assert(circleLeft(g, 4, 1) == 1 && g[1] == "chris" && g[3] == "ron");

    string c[] = { "ma", "can", "tu", "do" };
    assert(reduplicate(c, 4) == 4 && c[0] == "mama" && c[3] == "dodo");

    string e[] = { "asa", "vivek", "", "chris" };
    assert(subsequence(h, 7, e, 4) == 2);

    string d[] = { "ron", "ron", "ron", "chris", "chris" };
    assert(enumerateRuns(d, 5) == 2);

    string f[] = { "vivek", "asa", "tim" };
    assert(locateAny(h, 7, f, 3) == 2);
    assert(flip(f, 3) == 3 && f[0] == "tim" && f[2] == "vivek");

    assert(divide(h, 7, "donald") == 3);

    string i[] = { "ron", "vivek", "asa", "tim" };
    assert(divide(i, 4, "tim") == 2);

    cout << "All tests succeeded" << endl;
}
