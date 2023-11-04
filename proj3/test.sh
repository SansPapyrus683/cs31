#!/bin/bash

NAME=picture
QTR=fall23

# case $(hostname) in
#  lnxsrv0[679].seas.ucla.edu) ;;
#  lnxsrv11.seas.ucla.edu) ;;
#  cs31.seas.ucla.edu) ;;
#  *)	cat <<\END-END-END
# You must log into cs31.seas.ucla.edu to run this tester.
# END-END-END
# 	exit 1 ;;
# esac

GXX=g++

if [ ! -r $NAME.cpp ]
 then	echo "Your current directory is $PWD"
		echo "There is no readable file in this directory named $NAME.cpp"
		echo "Here's what's in this directory:"
		ls
		exit 1
fi

TESTNAME=xxxtest$NAME$$
TESTDIR=${TESTNAME}dir

if ! mkdir $TESTDIR 2> /dev/null
 then	echo "You don't have permission to create a directory in $PWD"
		exit 1
fi

SAVEDIR=$(pwd)
cd $TESTDIR  ||  exit 1
trap 'cd $SAVEDIR; rm -rf $TESTDIR' EXIT HUP INT TERM

curl -s -L http://cs.ucla.edu/classes/$QTR/cs31/Utilities/p3testerfiles.zip  \
	> $TESTNAME.zip
unzip -q -u $TESTNAME.zip

{ tr -d '\015\377\376\357\273\277' < ../$NAME.cpp ; echo ''
		cat <<\END-END-END ; } > $TESTNAME.cpp
#ifdef TESTERNEEDSMAIN
int main() {}
#endif
END-END-END

buildorig()
{
	 $GXX -o /dev/null -Werror=return-type "$@"  \
				$TESTNAME.cpp grid.cpp > ${TESTNAME}errs 2>&1
}

if ! buildorig  &&
   { ! grep 'undefined reference to `main' ${TESTNAME}errs > /dev/null  ||
		! buildorig -DTESTERNEEDSMAIN ; }
 then	cat <<\END-END-END
Your program failed to build, so it would earn no correctness points; here are
the error messages:
END-END-END
		sed -e "s,$TESTNAME,$NAME,"  \
		    -e '/^cc1plus: some warnings being treated as errors/d'  \
			   ${TESTNAME}errs
		exit 1
fi

grep '\<is[a-z][a-z]* *([^&|]*) *[=!]= *true' $TESTNAME.cpp |  \
	sed 's,//.*,,' | grep 'is.*true' > ${TESTNAME}badcctype
if [ -s ${TESTNAME}badcctype ]
 then	cat <<\END-END-END
***** CAUTION!!! *****
Your code contains the line(s):
END-END-END
		cat ${TESTNAME}badcctype
		cat <<\END-END-END
See the More Things about Strings writeup for the caution about testing the
return value of the isXXXXX functions for equality/inequality with true.
This might cause your code to behave incorrectly.
**********************
END-END-END
fi

{
	cat <<\END-END-END
#include <string>
#include <utility>

struct xxxstringexception
{
	xxxstringexception(std::string t, int p) : text(t), pos(p) {}
	std::string text;
	int pos;
};

struct xxxstring : public std::string
{
	using std::string::string;
	xxxstring() = default;
	xxxstring(const xxxstring& s) = default;
	xxxstring(xxxstring&& s) = default;
	xxxstring& operator=(const xxxstring& rhs) = default;
	xxxstring& operator=(xxxstring&& rhs) = default;
	xxxstring(const std::string& s) : std::string(s) {}
	xxxstring(std::string&& s) : std::string(std::move(s)) {}

	template<typename... Args>
	xxxstring& operator=(Args... args)
	{
		std::string::operator=(std::forward<Args...>(args...));
		return *this;
	}

	template<typename... Args>
	xxxstring& assign(Args... args)
	{
		std::string::assign(std::forward<Args...>(args...));
		return *this;
	}

	const char& at(size_t k) const
	{
		if (k >= size())
			throw xxxstringexception(*this, k);
		return std::string::at(k);
	}

	char& at(size_t k)
	{
		return const_cast<char&>(const_cast<const xxxstring&>(*this).at(k));
	}

	const char& operator[](size_t k) const
	{
		if (k > size())
			throw xxxstringexception(*this, k);
		return std::string::operator[](k);
	}

	char& operator[](size_t k)
	{
		return const_cast<char&>(const_cast<const xxxstring&>(*this)[k]);
	}
};

void isxxxxxWarning(const char* name);

struct xxxIntProxy
{
	int i;
	const char* name;

	xxxIntProxy(int ii, const char* n)
	 : i(ii), name(n)
	{}

	operator int() const
	{
		return i;
	}

	bool operator==(int rhs) const
	{
		if (rhs && i)
			isxxxxxWarning(name);
		return i == rhs;
	}

	bool operator!=(int rhs) const
	{
		return ! (*this == rhs);
	}
};

void xxxexitThrow(int);
xxxIntProxy xxxisdigit(int ch);
xxxIntProxy xxxisalpha(int ch);
xxxIntProxy xxxislower(int ch);
xxxIntProxy xxxisupper(int ch);
xxxIntProxy xxxisprint(int ch);

END-END-END
	sed -e '/#[	 ]*include[	 ]*<string\.*h*>/!s/\<string\>/xxxstring/g'  \
	    -e 's/\<std *:: *xxxstring\>/xxxstring/g'  \
	    -e 's/\<main[	 ]*([^)]*)/testmain [[gnu::no_sanitize_undefined]] () /'  \
	    -e 's/\(std *:: *\)*\<exit[	 ]*(\([^),]*\))/xxxexitThrow(\2)/'  \
	    -e 's/\(std *:: *\)*\(\<isdigit\>\)/xxx\2/g'  \
	    -e 's/\(std *:: *\)*\(\<isalpha\>\)/xxx\2/g'  \
	    -e 's/\(std *:: *\)*\(\<islower\>\)/xxx\2/g'  \
	    -e 's/\(std *:: *\)*\(\<isupper\>\)/xxx\2/g'  \
	    -e 's/\(std *:: *\)*\(\<isprint\>\)/xxx\2/g'  \
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
#include <utility>
#include <cctype>
#include <cstdlib>
#include <csignal>
#include <type_traits>
#include <unistd.h>
using namespace std;

#define string xxxstring

#define CHECKTYPE(f, t)  \
	{  \
	 static_assert(std::is_same<decltype(f), t>::value,  \
	   "Your declaration of " #f " has the wrong number or types of "  \
	   "parameters or the wrong return type.");  \
	 [[gnu::unused]] auto xxx##f = f;  \
	}

void xxxThisFunctionIsNeverCalled()
{
	CHECKTYPE(plotLine, bool(int, int, int, int, char, int));
	CHECKTYPE(performCommands, int(string, char&, int&, int&));
}

class InputForbidden {};
class OutputForbidden {};

class ThrowingStreambuf : public streambuf
{
  private:
	virtual int_type underflow()
	{
		throw InputForbidden();
	}

	virtual int_type overflow(int_type = traits_type::eof())
	{
		throw OutputForbidden();
	}
};

class StreambufSwitcher
{
  public:
	StreambufSwitcher(ios& str, streambuf* sb,
					ios::iostate exceptions = ios::goodbit)
	 : dest_stream(str), oldsb(str.rdbuf(sb)), oldex(str.exceptions())
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

ostringstream xxxwarningStream;

void isxxxxxWarning(const char* name)
{
	if (xxxwarningStream.str().empty())
	{
		xxxwarningStream << "Testing the result of is" << name << " for equality/inequality with true may cause your" << endl;
		xxxwarningStream << "code to behave incorrectly.  See the caution in More Things about Strings." << endl;
	}
}

#define xxxISFUNC(name)  xxxIntProxy xxxis##name(int ch)  \
	{  \
		return xxxIntProxy((is##name(ch) ? -98765 : 0), #name);  \
	}
xxxISFUNC(digit)
xxxISFUNC(alpha)
xxxISFUNC(lower)
xxxISFUNC(upper)
xxxISFUNC(print)

class Timeout {};
class ExitCalled {};

void exitThrow(int)
{
	throw ExitCalled();
}

const int XXXNROWS = 5;
const int XXXNCOLS = 10;

char xxxgrid[XXXNROWS][XXXNCOLS];

void xxxset(char ch, int r, int c)
{
	xxxgrid[r-1][c-1] = ch;
}

void xxxmakegrid()
{
	for (int r = 1; r <= XXXNROWS; r++)
		for (int c = 1; c <= XXXNCOLS; c++)
			xxxset(' ', r, c);
}

void xxxset(char ch, int pts[][2], int n)
{
	for (int k = 0; k < n; k++)
		xxxset(ch, pts[k][0], pts[k][1]);
}

bool xxxverify()
{
	for (int r = 1; r <= XXXNROWS; r++)
	{
		for (int c = 1; c <= XXXNCOLS; c++)
		{
			char actual = getChar(r, c);
			char expected = xxxgrid[r-1][c-1];
			if (actual != expected)
			{
					if (expected != ' ')
					{
						cout << " fails to set (" << r << "," << c
							 << ") to '" << expected << "' as expected" << endl;
					}
					else
					{
						cout << " fails to leave (" << r << "," << c
							 << ") unchanged" << endl;
					}
					return false;
			}
		}
	}
	return true;
}

const int xxxHORIZ = 0;
const int xxxVERT = 1;

const int xxxFG = 0;
const int xxxBG = 1;

template<typename F, typename... Args>
decltype(auto) testinvoke(F&& f, Args&&... args)
{
	xxxwarningStream.str("");
	ThrowingStreambuf tsb;
	StreambufSwitcher in(cin, &tsb, ios::badbit);
	StreambufSwitcher out(cout, &tsb, ios::badbit);
	return forward<F>(f)(forward<Args>(args)...);
}

int doTest(int testnum)
{
	char ch = '@';
	int mode = xxxFG;
	int badPos = -666;
	setSize(XXXNROWS, XXXNCOLS);
	xxxmakegrid();
	switch (testnum)
	{
	  case 1:
		xxxset('@', 3, 5);
		xxxset('@', 3, 6);
		xxxset('@', 3, 7);
		{
			bool bresult = testinvoke(plotLine, 3, 5, 2, xxxHORIZ, '@', xxxFG);
			if (!bresult)
			{
				cout << " returns false instead of true" << endl;
				return 1;
			}
		}
		break;
	  case 2:
		{
			bool bresult = testinvoke(plotLine, 3, 5, 2, xxxHORIZ, '@', 42);
			if (bresult)
			{
				cout << " returns true instead of false" << endl;
				return 1;
			}
		}
		break;
	  case 3:
		{
			int iresult = testinvoke(performCommands, "H?", ch, mode, badPos);
			if (iresult != 1)
			{
				cout << " returns " << iresult << " instead of 1" << endl;
				return 1;
			}
			if (badPos != 1)
			{
				cout << " fails to set its last parameter to 1" << endl;
				return 1;
			}
			if (ch != '@')
			{
				cout << " mistakenly changes its second parameter" << endl;
				return 1;
			}
			if (mode != xxxFG)
			{
				cout << " mistakenly changes its third parameter" << endl;
				return 1;
			}
		}
		break;
	  case 4:
		xxxset('@', 1, 1);
		xxxset('@', 1, 2);
		xxxset('@', 1, 3);
		{
			int iresult = testinvoke(performCommands, "H2", ch, mode, badPos);
			if (iresult != 0)
			{
				cout << " returns " << iresult << " instead of 0" << endl;
				return 1;
			}
			if (badPos != -666)
			{
				cout << " fails to leave its last parameter unchanged" << endl;
				return 1;
			}
			if (ch != '@')
			{
				cout << " mistakenly changes its second parameter" << endl;
				return 1;
			}
			if (mode != xxxFG)
			{
				cout << " mistakenly changes its third parameter" << endl;
				return 1;
			}
		}
		break;
	  case 5:
		xxxset('@', 1, 1);
		xxxset('@', 1, 2);
		xxxset('#', 1, 3);
		xxxset('#', 2, 3);
		xxxset('#', 3, 3);
		{
			int iresult = testinvoke(performCommands, "H2F#V2", ch, mode, badPos);
			if (iresult != 0)
			{
				cout << " returns " << iresult << " instead of 0" << endl;
				return 1;
			}
			if (badPos != -666)
			{
				cout << " fails to leave its last parameter unchanged" << endl;
				return 1;
			}
			if (ch != '#')
			{
				cout << " fails to set its second parameter to #" << endl;
				return 1;
			}
			if (mode != xxxFG)
			{
				cout << " mistakenly changes its third parameter" << endl;
				return 1;
			}
		}
		break;
	}
	if ( ! xxxverify())
		return 1;
	cout << endl;
	return 0;
}

int main(int argc, char* argv[])
{
	if (argc != 2)
	{
		cout << "Tester has missing or too many arguments" << endl;
		return 1;
	}

	int testnum = atoi(argv[1]);
	if (testnum < 1  ||  testnum > 5)
	{
		cout << "Invalid tester argument" << endl;
		return 1;
	}
	const string testmsg[5] = {
		"setSize(5,10); plotLine(3, 5, 2, HORIZ, '@', FG)",
		"setSize(5,10); plotLine(3, 5, 2, HORIZ, '@', 42)",
		"setSize(5,10); char pc = '@'; int m = FG; int bp; int r = performCommands(\"H?\", pc, m, bp);",
		"setSize(5,10); char pc = '@'; int m = FG; int bp; int r = performCommands(\"H2\", pc, m, bp);",
		"setSize(5,10); char pc = '@'; int m = FG; int bp; int r = performCommands(\"H2F#V2\", pc, m, bp);",
	};
	cout << testmsg[testnum-1] << flush;

	future<int> f;
	try
	{
		f = move(async(doTest, testnum));
		int timeout = 3;
		if (f.wait_for(chrono::seconds(timeout)) != future_status::ready)
			throw Timeout();
		int exitStatus = f.get();
		cout << xxxwarningStream.str();
		return exitStatus;
	}
	catch (const InputForbidden&)
	{
		cout << " attempts to read from cin, which the spec forbids." << endl;
	}
	catch (const OutputForbidden&)
	{
		cout << " attempts to write to cout, which the spec forbids.  "
			"(Write to cerr instead.)" << endl;
	}
	catch (const Timeout&)
	{
		kill(getpid(), SIGUSR2);
	}
	catch (const xxxstringexception& ex)
	{
		cout << " attempts to access position " << ex.pos
		     << " of the " << ex.text.size()
		     << "-character string \"" << ex.text << "\"." << endl;
	}
	catch (const ExitCalled&)
	{
		cout << "calls exit instead of returning a value required by "
		     << "the spec." << endl;
	}
	catch (...)
	{
		cout << "throws an unexpected exception." << endl;
	}
	cout << xxxwarningStream.str();
	return 1;
}
END-END-END
} > $TESTNAME.cpp2
mv $TESTNAME.cpp2 $TESTNAME.cpp

if ! $GXX -Wno-return-type -o $TESTNAME $TESTNAME.cpp grid.cpp -lpthread  \
	> ${TESTNAME}errs2 2>&1
 then	if egrep "'(hasCorrectForm|determineSafeDistance|obeyPlan)' was not declared in this scope"  \
			${TESTNAME}errs2 | sed "s/.*error: '/  /;s/' was not.*//" | sort -u > ${TESTNAME}und
		[ -s ${TESTNAME}und ]
	 then	suffix=s
		[ $(wc -l < ${TESTNAME}und) -eq 1 ]  &&  suffix=
		echo "Your program failed to declare the following function$suffix:"
		cat ${TESTNAME}und - <<\END-END-END
which you either misspelled or didn't declare anything like at all.
END-END-END
		exit 1
	fi
	if grep 'Your declaration of ' ${TESTNAME}errs2 > ${TESTNAME}assert
	 then	cat <<\END-END-END
Although your program builds successfully by itself, there's something wrong
with it that's causing it to fail to build with our test harness. 
END-END-END
			sed 's/^.*assertion failed: //' ${TESTNAME}assert
			exit 1
	fi
	cat <<\END-END-END
Although your program builds successfully by itself, there's something wrong
with it that's causing it to fail to build with our test harness.  Here are
the error messages:

END-END-END
	sed "s,$TESTNAME,tester$NAME," ${TESTNAME}errs2
	mv $TESTNAME.cpp ../tester$NAME.cpp
	exit 1
fi

allpassed=y
for (( n=1 ; n <= 5 ; n++ ))
 do	if (( n > 1 ))
	 then	echo ''
	fi
	echo "========== TEST $n =========="
	exec 3>&2-
	exec 2> /dev/null
	ASAN_OPTIONS=exitcode=119 ./$TESTNAME $n
	status=$?
	exec 2>&3-
	if (( status == 119 ))
	 then	echo " does something undefined, perhaps accessing an invalid position in a string."
	elif (( status == 140 ))  # SIGUSR2
	 then	echo " puts your program into an infinite loop."
	elif (( status >= 128 ))
	 then	echo " crashed your program because it did something with undefined behavior."
	fi
	echo -n "========== TEST $n "
	if (( status == 0 ))
	 then	echo "PASSED =========="
	 else	echo "FAILED!!! ======="
			allpassed=n
	fi
 done
echo ''
echo '=============== SUMMARY ============'
if [[ $allpassed = y ]]
 then	cat <<\END-END-END
Although these tests are by no means complete, your passing them means you
probably didn't make a systematic mistake that would cause you to lose most
of the correctness points.
END-END-END
 else	cat << \END-END-END
*** AT LEAST ONE OF THESE TEST CASES FAILED. ***
Because your code failed at least one of these five test cases, it is likely
to fail a significant number of the test cases with which we grade its
correctness, resulting in a low score.
END-END-END
fi
