echo off
if not exist "c:\localtemp"  mkdir "c:\localtemp"
copy /Y "c:\cpi\cad\ciscoC8.dat" "c:\localtemp\ciscoC8.dat"
copy /Y "c:\cpi\cad\ciscoC8.alt" "c:\localtemp\ciscoC8.alt"