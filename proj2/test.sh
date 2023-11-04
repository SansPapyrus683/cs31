#!/bin/bash

NAME=fine

# case $(hostname) in
#  lnxsrv0[679].seas.ucla.edu) ;;
#  lnxsrv11.seas.ucla.edu) ;;
#  cs31.seas.ucla.edu) ;;
#  *)     cat <<\END-END-END
# You must log into cs31.seas.ucla.edu to run this tester.
# END-END-END
#         exit 1 ;;
# esac

GXX=/usr/bin/g++

if [ ! -r $NAME.cpp ]
 then   echo "Your current directory is $PWD"
        echo "There is no readable file in this directory named $NAME.cpp"
        echo "Here's what's in this directory:"
        ls
        exit 1
fi

TESTNAME=xxxtest$NAME$$
trap 'rm -f $TESTNAME*' EXIT HUP INT TERM

{ tr -d '\015\377\376\357\273\277' < $NAME.cpp ; echo '' ; } > $TESTNAME.cpp

if ! $GXX -Werror=return-type -o /dev/null $TESTNAME.cpp > ${TESTNAME}errs 2>&1
 then   cat <<\END-END-END
Your program failed to build, so it would earn no correctness points; here are
the error messages:
END-END-END
        sed -e "s/$TESTNAME/$NAME/"  \
            -e '/^cc1plus: some warnings being treated as errors/d'  \
            ${TESTNAME}errs
        exit 1
fi

{
        cat <<\END-END-END
void exitThrow(int);

END-END-END
        sed -e 's/\<main[        ]*([^)]*)/testmain [[gnu::no_sanitize_undefined]] () /'  \
            -e 's/\(std *:: *\)*\<exit[  ]*(\([^),]*\))/exitThrow(\2)/'  \
            $TESTNAME.cpp
        echo ''
        cat <<\END-END-END
#include <iostream>
#include <sstream>
#include <streambuf>
#include <string>
#include <thread>
#include <future>
#include <chrono>
#include <algorithm>
#include <cstdio>
#include <cstdlib>
#include <unistd.h>
using namespace std;

struct Stdin
{
        int operator()() { return getchar(); }
        bool isatty() const { return ::isatty(0); }
};

template<typename In>
class EchoInputStreambuf : public streambuf
{
  public:
        EchoInputStreambuf(In f = In())
         : input(f)
        {
                // allow 4 chars of pushback
                setg(buffer+4, buffer+4, buffer+4);
        }

  private:
        In input;
        enum { buffersize = 10000 };
        char buffer[buffersize];

        virtual int underflow()
        {
                if (gptr() < egptr())
                        return *gptr();
                int numPutback = gptr() - eback();
                if (numPutback > 4)
                        numPutback = 4;
                copy(gptr()-numPutback, gptr(), buffer+(4-numPutback));
                char_type* p = buffer+4;
                for (int nleft = buffersize-4; nleft > 0; nleft--)
                {
                        int ch = input();
                        if (ch == traits_type::eof())
                                return traits_type::eof();
                        *p++ = ch;
                        if (!input.isatty())
                                cout.rdbuf()->sputc(ch);
                        if (ch == char_type('\n'))
                                break;
                }
                setg(buffer+(4-numPutback), buffer+4, p);
                return *gptr();
        }
};

class StreambufSwitcher
{
    public:
        StreambufSwitcher(ios& dest, streambuf* sb,
                                        ios::iostate exceptions = ios::goodbit)
         : dest_stream(dest), oldsb(dest.rdbuf(sb)), oldex(dest.exceptions())
        { dest_stream.exceptions(exceptions); }
        StreambufSwitcher(ios& dest, ios& src)
         : StreambufSwitcher(dest, src.rdbuf(), src.exceptions())
        {}
        ~StreambufSwitcher()
        { dest_stream.rdbuf(oldsb); dest_stream.exceptions(oldex); }
    private:
        ios& dest_stream;
        streambuf* oldsb;
        ios::iostate oldex;
};

class Timeout {};
class ExitCalled {};

void exitThrow(int)
{
        throw ExitCalled();
}

int main(int argc, char* argv[])
{
        if (argc != 2)
        {
                cout << "Tester has missing or too many arguments" << endl;
                return 1;
        }

        ostringstream oss;
        future<int> f;
        try
        {
                EchoInputStreambuf<Stdin> sb;
                StreambufSwitcher ssin(cin, &sb);
                StreambufSwitcher ssout(cout, oss);
                f = move(async(testmain));
                int timeout = 3;
                if (f.wait_for(chrono::seconds(timeout)) != future_status::ready)
                        throw Timeout();
                void(f.get());
        }
        catch (const Timeout&)
        {
                cout << endl << "XXXTIMEOUTXXX" << endl;
                terminate();
        }
        catch (const ExitCalled&)
        {
        }
        string s = oss.str();
        if (!s.empty()  &&  s.back() != '\n')
                s += '\n';
        const string MISSING_IGNORE_HYPHENS = "\nLocation: ---\n";
        const string HYPHENS = "\n---\n";
        string::size_type p = s.find(MISSING_IGNORE_HYPHENS);
        if (p != string::npos)
                p += MISSING_IGNORE_HYPHENS.size();
        else
        {
                p = s.find(HYPHENS);
                if (p == string::npos)
                {
                        cout << "You didn't write to cout a line of exactly three hyphens." << endl;
                        return 1;
                }
                p += HYPHENS.size();
        }
        if (s.find('\n', p) != s.size()-1)
        {
                cout << "You didn't write to cout *exactly* one line after the line of three hyphens." << endl;
                return 1;
        }
        if (s.compare(p, s.size()-p, argv[1]) != 0)
        {
                cout << "After the line of three hyphens, you didn't write to cout *exactly* the "
                     << endl << "following expected line:" << endl << argv[1];
                return 1;
        }
        return 0;
}
END-END-END
} > $TESTNAME.cpp2
mv $TESTNAME.cpp2 $TESTNAME.cpp

if ! $GXX -Wno-return-type -o $TESTNAME $TESTNAME.cpp -lpthread > ${TESTNAME}errs2 2>&1
 then   cat <<\END-END-END
Although your program builds successfully by itself, there's something wrong
with it that's causing it to fail to build with our test harness.  Here are
the error messages:
END-END-END
        sed "s/$TESTNAME/tester$NAME/" ${TESTNAME}errs2
        mv $TESTNAME.cpp tester$NAME.cpp
        exit 1
fi

declare -a in=( $'International Hotel Vancouver\n-103\ncanada\n'
                $'International Hotel Vancouver\n103\ncanada\n'
              )
declare -a out=($'The overstated amount must be positive.\n'
                $'The fine for International Hotel Vancouver is $13.245 million.\n'
               )

allpassed=y
for (( n=0 ;  n < ${#in[@]} ; n++ ))
 do     if (( n > 0 ))
         then   echo ''
        fi
        echo "========== TEST #$((n+1)) input =========="
        echo -n "${in[n]}"
        echo -n "========== TEST #$((n+1)) "
        (echo -n "${in[n]}" |
                        ./$TESTNAME "${out[n]}" > ${TESTNAME}out) 2> /dev/null
        status=$?
        if (( status == 0 ))
         then   echo "PASSED =========="
         else   echo "FAILED!!! ======="
                allpassed=n
                if (( status < 128 ))
                 then   cat ${TESTNAME}out
                elif [ "$(tail -1 ${TESTNAME}out)" = XXXTIMEOUTXXX ]
                 then   echo "Your program probably went into an infinite loop."
                else
                        echo "Your program crashed because it did something with undefined behavior."
                fi
        fi
 done
echo ''
echo "=============== SUMMARY ============"
if [[ $allpassed = y ]]
 then   cat <<\END-END-END
Although these tests are by no means complete, your passing them means you
probably didn't make a systematic mistake that would cause you to lose most
of the correctness points.
END-END-END
 else   cat <<\END-END-END
If you turn in your program as is, you will probably lose most of the
correctness points.
END-END-END
fi
