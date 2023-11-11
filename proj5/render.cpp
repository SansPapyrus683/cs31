#include <cstring>
#include <cctype>
#include <fstream>
#include <iostream>

using namespace std;

constexpr int MAX_WORD_LEN = 180;

bool isPunctuation(char c) {
    return strchr(".?!:", c) != NULL;
}

/** @return the number of spaces needed after a word */
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

    char lastPrinted[MAX_WORD_LEN + 1];  // +1 for null terminator
    lastPrinted[0] = '\0';
    int currLen = 0;

    int retCode = 0;
    bool lastWasPara = true;  // was the last thing we outputted a paragraph?
    bool anything = false;  // did we even read in any words
    char word[MAX_WORD_LEN + 1];
    while (inf >> word) {
        // first check if we should handle this as a paragraph
        if (strcmp(word, "@P@") == 0) {
            if (!lastWasPara) {
                // reset & print only if the last token wasn't a paragraph
                outf << "\n\n";
                lastPrinted[0] = '\0';
                currLen = 0;
                lastWasPara = true;
            }
            continue;
        }

        int len = strlen(word);  // shorthand
        int prev = 0;  // the starting index of the current word portion
        for (int i = 0; i < len; i++) {
            // end a word portion at a hyphen or at the end of the word
            if (word[i] == '-' || i == len - 1) {
                int pLen = i - prev + 1;  // the length of the word part
                
                char slice[MAX_WORD_LEN + 1];
                strncpy(slice, word + prev, pLen);
                slice[pLen] = '\0';  // c sucks
                
                int spaces = spacesAfter(lastPrinted);
                // the current word along with the previous spaces have to fit
                if (currLen + spaces + pLen > linLen) {
                    // output linLen length chunks of the string until the end
                    for (int at = 0; at < pLen; at += linLen) {
                        outf << '\n';
                        for (int j = at; j < min(pLen, at + linLen); j++) {
                            outf << slice[j];
                        }
                    }
                    if (pLen > linLen) {
                        retCode = 1;
                    }
                    currLen = len % linLen;
                } else {
                    // if it fits, we can just output the spaces & the word
                    for (int i = 0; i < spaces; i++) {
                        outf << ' ';
                    }
                    outf << slice;
                    currLen += spaces + len;
                }

                strcpy(lastPrinted, slice);  // update the last word printed

                prev = i + 1;  // and the start of the next word
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
    ifstream infile("test.txt");

    cout << "Enter maximum line length: ";
    int len;
    cin >> len;

    ofstream outfile("output.txt");
    int returnCode = render(len, infile, outfile);
    cout << "Return code is " << returnCode << endl;
}
