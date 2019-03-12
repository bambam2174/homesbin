
EXAMPLES
     To find all occurrences of the word `patricia' in a file:

           $ grep 'patricia' myfile

     To find all occurrences of the pattern `.Pp' at the beginning of a line:

           $ grep '^\.Pp' myfile

     The apostrophes ensure the entire expression is evaluated by grep instead of by the user's shell.  The caret `^' matches the null string at the begin-
     ning of a line, and the `\' escapes the `.', which would otherwise match any character.

     To find all lines in a file which do not contain the words `foo' or `bar':

           $ grep -v -e 'foo' -e 'bar' myfile

     A simple example of an extended regular expression:

           $ egrep '19|20|25' calendar

     Peruses the file `calendar' looking for either 19, 20, or 25.

