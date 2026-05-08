# sentry-native-build-script
scripts for build sentry-native client

# build for Windows VS 2022 Community Editon

clone project https://github.com/getsentry/sentry-native
```bash
git clone git@github.com:getsentry/sentry-native.git
```
run build_vs2022.bat
```bash
build_vs2022.bat
```
Output folders in same directory:
```
output\
  \Shared-CRT_Shared
    \x64
      \Debug
      \Release
    \x86
      ...
  \Shared-CRT_Static
    \x64
      ...
    \x86
      ...
```
