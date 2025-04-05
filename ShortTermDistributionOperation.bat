@echo off

SET BASEPATH=%~dp0

CALL julia "%BASEPATH%\main.jl" "%*"