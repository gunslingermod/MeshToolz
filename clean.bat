del *.~pas
del *.bak
del *.dcu
del *.lps
del *.exe
del *.log

del lowlevel\*.~pas
del lowlevel\*.bak
del lowlevel\*.dcu
rmdir /S /Q lowlevel\backup

del tests\*.~pas
del tests\*.bak
del tests\*.dcu
rmdir /S /Q tests\backup

rmdir /S /Q lib
rmdir /S /Q backup
exit