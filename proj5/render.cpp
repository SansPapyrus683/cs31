#include <cstring>
#include <cctype>
#include <fstream>
#include <iostream>

using namespace std;

constexpr int MAX_WORD_LEN = 180;

bool isPunctuation(char c) {
    return strchr(".?!:", c) != NULL;
}

int spacesAfter(char str[]) {
    int len = strlen(str);
    return len == 0 ? 0 : (isPunctuation(str[len - 1]) ? 2 : 1);
}

int min(int a, int b) {
    return a < b ? a : b;
}

int render(int linLen, istream& inf, ostream& outf) {
    if (linLen < 1) {
        return 2;
    }

    char lastPrinted[MAX_WORD_LEN + 1];
    lastPrinted[0] = '\0';
    int currLen = 0;

    int retCode = 0;
    bool lastWasPara = true;
    bool anything = false;
    char word[MAX_WORD_LEN + 1];  // +1 for null terminator
    while (inf >> word) {
        if (strcmp(word, "@P@") == 0) {
            if (!lastWasPara) {
                outf << "\n\n";
                lastPrinted[0] = '\0';
                currLen = 0;
                lastWasPara = true;
            }
            continue;
        }

        int len = strlen(word);
        int prev = 0;
        for (int i = 0; i < len; i++) {
            if (word[i] == '-' || i == len - 1) {
                int pLen = i - prev + 1;
                
                char slice[MAX_WORD_LEN + 1];
                strncpy(slice, word + prev, pLen);
                slice[pLen] = '\0';
                
                int spaces = spacesAfter(lastPrinted);
                if (currLen + spaces + pLen > linLen) {
                    for (int at = 0; at < pLen; at += linLen) {
                        outf << '\n';
                        for (int j = at; j < min(pLen, at + linLen); j++) {
                            outf << slice[j];
                        }
                    }
                    currLen = len % linLen;
                } else {
                    for (int i = 0; i < spaces; i++) {
                        outf << ' ';
                    }
                    outf << slice;
                    currLen += spaces + len;
                }

                strcpy(lastPrinted, slice);

                prev = i + 1;
            }
        }
        anything = true;
        lastWasPara = false;
    }
    if (anything) {
        outf << '\n';
    }

    return retCode;
}

int main() {
    const int MAX_FILENAME_LENGTH = 100;
    cout << "Enter input file name: ";
    char filename[MAX_FILENAME_LENGTH];
    cin.getline(filename, MAX_FILENAME_LENGTH);

    ifstream infile(filename);
    if (!infile) {
        cerr << "Cannot open " << filename << "!" << endl;
        return 1;
    }

    cout << "Enter maximum line length: ";
    int len;
    cin >> len;
    cin.ignore(10000, '\n');

    ofstream outfile("output.txt");
    int returnCode = render(len, infile, outfile);
    cout << "Return code is " << returnCode << endl;
}
