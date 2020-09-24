echo off
echo Start optimizing in directory %1 > LinksOptimizer.log
for /r "%1"  %%i in (*.ogf) do (
echo ------------------  >> LinksOptimizer.log
LinksOptimizer.exe "%%i" >> LinksOptimizer.log
)
