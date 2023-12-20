
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

     -------------------------------------------------------
     Have a look at those hidden scripts with the word `generic` in them starting with a dot to make them hidden and the symlinks pointing to them.
     The filename of the such a symlink defines different behaviours, e.g. the output of certain special characters behind variable names or the function itself.

