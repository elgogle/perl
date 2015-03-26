echo off
if not exist "c:\localtemp"  mkdir "c:\localtemp"
copy /Y "c:\cpi\cad\cisco4_12.dat" "c:\localtemp\cisco4_12.dat"
copy /Y "c:\cpi\cad\cisco4_12.alt" "c:\localtemp\cisco4_12.alt"