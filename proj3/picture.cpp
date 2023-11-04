#include <iostream>
#include <string>
#include <limits>
#include <cassert>

#include "grid.h"

using namespace std;

const int HORIZ = 0;
const int VERT = 1;

const int FG = 0;
const int BG = 1;

/** @return whether the given point fits within the bounds of the grid */
bool validPoint(int r, int c) {
    return 0 < r && r <= getRows() && 0 < c && c <= getCols();
}

bool plotLine(int r, int c, int distance, int dir, char plotChar, int fgbg) {
    // stupid input validation here
    if (!(dir == HORIZ || dir == VERT) || !(fgbg == FG || fgbg == BG)) {
        return false;
    }
    if (!validPoint(r, c) || !isprint(plotChar)) {
        return false;
    }

    // should we go forward or backward?
    int incr = distance >= 0 ? 1 : -1;
    if (dir == HORIZ) {
        int target = c + distance;
        // as long as the start and end are valid we chillin
        if (!validPoint(r, target)) {
            return false;
        }
        for (int i = c; i != target + incr; i += incr) {
            if (fgbg == FG || (fgbg == BG && getChar(r, i) == ' ')) {
                setChar(r, i, plotChar);
            }
        }
    } else if (dir == VERT) {
        int target = r + distance;
        if (!validPoint(target, c)) {
            return false;
        }
        for (int i = r; i != target + incr; i += incr) {
            if (fgbg == FG || (fgbg == BG && getChar(i, c) == ' ')) {
                setChar(i, c, plotChar);
            }
        }
    }

    return true;
}

int performCommands(string cmd, char& plotChar, int& mode, int& badPos) {
    if (!isprint(plotChar) || !(mode == FG || mode == BG)) {
        return 2;
    }

    int DIG = 2;  // max this many digits
    // parses and returns the ending index (exclusive) of a # starting @ start
    auto parseNum = [&] (int start) {
        int mul = 1;
        if (cmd[start] == '-') {  // process a starting - sign if needed
            start++;
            mul = -1;
        }
        if (start < cmd.size() && isdigit(cmd[start])) {
            int end = start + 1;
            // read until we hit max digits or smth that isn't a #
            for (; end < start + DIG && isdigit(cmd[end]); end++);
            int num = stoi(cmd.substr(start, end - start));
            return make_pair(num * mul, end - 1);
        }
        return make_pair(INT32_MIN, start);
    };

    // H2V3H99V2F中H3
    // current row, col, and index @ cmd string respectively
    int r = 1;
    int c = 1;
    int i = 0;
    int oobPos = INT32_MAX;
    while (i < cmd.size()) {
        char curr = cmd[i];
        curr = tolower(curr);  // if invalid char, curr is unchanged

        // hacky fix, but whatever
        if (string("hvfb").find(curr) != string::npos && i == cmd.size() - 1) {
            badPos = i + 1;
            return 1;
        }

        // for some goddamned reason you can't declare vars in switches
        if (curr == 'h') {
            int start = i;
            const auto& [num, ind] = parseNum(++i);
            if (num == INT32_MIN) {
                badPos = ind;
                return 1;
            }
            bool res = plotLine(r, c, num, HORIZ, plotChar, mode);
            if (!res) {  // the plotLine must have gone OOB
                oobPos = min(oobPos, start);
            }
            i = ind;  // move i to end of curr command
            c += num;
        } else if (curr == 'v') {
            int start = i;
            const auto& [num, ind] = parseNum(++i);
            if (num == INT32_MIN) {
                badPos = ind;
                return 1;
            }
            bool res = plotLine(r, c, num, VERT, plotChar, mode);
            if (!res) {
                oobPos = min(oobPos, start);
            }
            i = ind;
            r += num;
        } else if (curr == 'f') {
            char setChar = cmd[++i];
            if (!isprint(setChar)) {
                badPos = i;
                return 1;
            }
            plotChar = setChar;
            mode = FG;
        } else if (curr == 'b') {
            char setChar = cmd[++i];
            if (!isprint(setChar)) {
                badPos = i;
                return 1;
            }
            plotChar = setChar;
            mode = BG;
        } else if (curr == 'c') {
            r = 1;
            c = 1;
            plotChar = '*';
            clearGrid();
            mode = FG;
        } else {
            badPos = i;
            return 1;
        }
        i++;
    }

    if (oobPos != INT32_MAX) {
        badPos = oobPos;
        return 3;
    }
    return 0;
}

int main() {
    while (true) {
        cout << "Enter the number of grid rows and columns (max 30 each): ";
        int rows;
        int cols;
        cin >> rows >> cols;
        if (cin.fail()) {
            cin.clear();
        }
        cin.ignore(numeric_limits<streamsize>::max(), '\n');
        if (rows >= 1 && rows <= MAXROWS && cols >= 1 && cols <= MAXCOLS) {
            setSize(rows, cols);
            break;
        }
        cout << "The numbers must be between 1 and 30." << endl;
    }

    char currChar = '*';
    int currMode = FG;
    while (true) {
        cout << "Enter a command string (empty line to quit): ";
        string cmd;
        getline(cin, cmd);
        if (cmd == "") {
            break;
        }

        int pos;
        int status = performCommands(cmd, currChar, currMode, pos);
        switch (status) {
          case 0:
            draw();
            break;
          case 1:
            cout << "Syntax error at position " << pos << endl;
            break;
          case 2:
            if (!isprint(currChar)) {
                cout << "Current character is not printable" << endl;
            }
            if (currMode != FG  ||  currMode != BG) {
                cout << "Current mode is " << currMode << ", not FG or BG" << endl;
            }
            break;
          case 3:
            cout << "Cannot perform command at position " << pos << endl;
            break;
          default:
              // It should be impossible to get here.
            cout << "performCommands returned " << status << "!" << endl;
        }
    }
}
