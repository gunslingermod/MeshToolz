echo off
echo Start optimizing in directory %1 > %~dp0\LinksOptimizer.log
for /r "%1"  %%i in (*.ogf) do (
echo ------------------  >> %~dp0\LinksOptimizer.log
echo Optimizing file %%i >> %~dp0\LinksOptimizer.log
%~dp0\LinksOptimizer.exe "%%i" >> %~dp0\LinksOptimizer.log
)