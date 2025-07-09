# CleanIDE

The Clean IDE is currently only available for Windows. However using the wine tool
you can run the CleanIDE on both Linux and MacOS.

## Run CleanIDE.exe on Linux or MacOS with wine

Just do the following to run the CleanIDE.exe with wine on

```bash

CLEAN_URL="https://ftp.cs.ru.nl/Clean/Clean31/windows/Clean_3.1_64.zip"
curl -L -o "clean.zip" "$CLEAN_URL"
unzip "clean.zip"
wine "Clean 3.1/CleanIDE.exe"
#    or with a project file
wine "Clean 3.1/CleanIDE.exe" "somedir\myproject.prj"
```

Important to note that Wine is not perfect. Some Windows API's are not good
implemented. However most things work fine.

## CleanIDE App on Macos (running CleanIDE.exe on wine)

First you need to install wine. On MacOS you an easily install wine using homebrew
with the command:

```bash
brew install wine-stable
```

Download the
[`CleanIDE.app`](https://github.com/harcokuppens/clean-classic-helloworld/releases/download/macOS_application/CleanIDE.app.zip)
from
[here](https://github.com/harcokuppens/clean-classic-helloworld/releases/download/macOS_application/CleanIDE.app.zip).
Unzip it and move the 'CleanIDE.app' to your `/Applications/` folder.

The `CleanIDE.app` supports:

- open `.prj`,`dcl`, and `.icl` files fron the Finder\
- drag & drop of `.prj`,`dcl`, and `.icl` files

Note that this requires you first have to associate them to the CleanIDE.app via the
Finder's "Get Info" context menu. You can also do this with the `duti` command:

```bash
$ brew install duti
$ duti -s nl.ru.cs.wineclean .prj all
$ duti -s nl.ru.cs.wineclean .icl all
$ duti -s nl.ru.cs.wineclean .dcl all
```

### Nitrile projects supported by `CleanIDE.app`

The `CleanIDE.app` also supports nitrile projects which use the Clean tools
(compiler/linker/code generator) installed as nitrile packages in the project itself.
The `CleanIDE.app` requires the tools to be installed as Windows nitrile packages,
because the CleanIDE.exe is run with wine. Therefore to build the project we need
Windows libraries and executables.

The`CleanIDE.app` automatically detects a nitrile project when it uses a 'nitrile'
environment in its project file, otherwise it will handled it as a 'classic' clean
project which uses the Clean tools and libraries in the CleanIDE.app itself.

The
[Clean nitrile example project](https://github.com/harcokuppens/clean-nitrile-helloworld.git)
uses a Clean distribution installed with the `nitrile` tool. The project includes a
simple “Hello, World!” console application, but it can also serve as a template for
building other projects using `nitrile`. This project has special support for
creating a windows nitrile project on MacOS, which you then can compile with the
windows 'cpm' on wine or edit with the CleanIDE. The created Windows nitrile project
uses the 'nitrile' environment in its project file and can be opened with the MacOS
`CleanIDE.app`. To quickly get started follow this project's
[instructions for setting up a windows nitrile project which can be build with cpm using wine](https://github.com/harcokuppens/clean-nitrile-helloworld.git#cpm-build-using-wine-on-macoslinux-for-both-x64-and-arm).

### Work around for annoying permission dialogs

MacOS adds extra protection, called TCC, to some folders in your home directory, eg.
~/Desktop ~/Documents. When opening a Clean file from one of these specially
protected folders you have to many times allow the same permission. Somehow the
permission does not stick in wine. This is annoying. A good work around is by not
putting your Clean project in such protected folder.

Instead of putting your CleanIDE project in:

      ~/Documents/CleanIDE_Projects/MyProject

Put it in:

      ~/CleanIDE_Projects/MyProject

### Limitations of CleanIDE.exe on MacOS

- The binaries build are Windows binaries, and must als be run using wine. However
  you can run the build binaries within the Clean app, or when you install the
  commandline version of Clean for MacOS you can build binaries which work directly
  on MacOS.

- Wine is not perfect. Some Windows API's are not good implemented. For example the
  project `examples/PlatformExamples/IPLookup.prj` builds in the CleanIDE and runs,
  but does print the empty string. When you install the MacOS version of Clean and
  build it with the commandline using `cpm` then it works fine!

- the MacOS application always launches a new Clean IDE instance.

### Background: how we created the MacOS app for Windows CleanIDE GUI app running with wine on MacOS

Requirements:

- Platypus app from https://sveinbjorn.org/platypus \
   After installing Platypus app install the platypus command via the App by pressing
  an install button at:

  ```
  menu "Platypus -> Settings -> click "Install" button
  ```

- wine \
  on MacOS you an easily install wine using homebrew with the command:

  ```bash
  brew install wine-stable
  ```

Using the Platypus app you then can easily create a MacOS application using the
`create-app.bash` script. We use it to create a MacOS application
[`CleanIDE.app`](https://github.com/harcokuppens/clean-classic-helloworld/releases/download/macOS_application/CleanIDE.app.zip)
for the Windows CleanIDE.exe which runs in the background with wine.

This App can be easily created with the command:

```bash
./create-app.bash
```

which causes a `CleanIDE.app/` app folder to be created in the current folder.

### Background: explanation of limitations of CleanIDE on MacOS:

        On Windows you have 2 ways to launch:

            - run via file associations

                * click on "FILE.icl" file in explorer : opens in existing Clean IDE instance
                * this is the same as running in terminal the command:

                          start  "" FILE.icl

                * For file associations to work, the CleanIDE.exe must be configured
                  as the default application for ".icl" files.

            - run as program argument

                * in windows terminal: run the command

                         cleanIDE.exe FILE.icl

                  this always opens a new Clean IDE instance.

                *  this is the same as running in terminal the command:


                          start CleanIDE.exe file.icl

                * The CleanIDE.exe does not need to be configured
                  as the default application for ".icl" files.

            - for more details see:

                 Understanding_the_start_Command_and_File_explorer_behaviourGemini.md

        On MacOS using wine: start is broken:

            In real Windows, the "start" (and shell file associations) can invoke an existing program window using advanced
            messaging like DDE (Dynamic Data Exchange) or COM.
            CleanIDE (like many Windows apps) probably uses DDE or similar to receive new files when already open.

            In Wine, those mechanisms are either partially implemented or not implemented at all, so every

                start "" FILE.icl

            gives an error

                 Application could not be started, or no application associated with the specified file.
                 ShellExecuteEx failed: File not found.

            for example run:

                $ wine start "" "Z:\Applications\CleanIDE.app\Contents\Resources\clean3.1\Examples\Small Examples\acker.icl"
                Application could not be started, or no application associated with the specified file.
                ShellExecuteEx failed: File not found.

            ends up launching a new process, because there's no way for Wine to "tell" CleanIDE
            to reuse the existing window. So in wine it is impossible to open the icl file
            in an existing instance of clean. This is due to lack of good DDE implementation in wine.

            We applied the exact same file associations for Clean in Windows by running:

                wine regedit  clean.reg

            Note: we apply the keys both to HKEY_CURRENT_USER  and HKEY_LOCAL_MACHINE, because in wine it seemed
                  to be only applied to HKEY_CURRENT_USER by the CleanIDE, whereas in windows the keys are applied to both.
                  However file association still doesn't work in wine!

            Instead we have to do:

              wine start  "Z:\Applications\CleanIDE.app\Contents\Resources\clean3.1\CleanIDE.exe"  \
                "Z:\Applications\CleanIDE.app\Contents\Resources\clean3.1\Examples\Small Examples\acker.icl"

                    or

              wine "Z:\Applications\CleanIDE.app\Contents\Resources\clean3.1\CleanIDE.exe"  \
                "Z:\Applications\CleanIDE.app\Contents\Resources\clean3.1\Examples\Small Examples\acker.icl"

            both commands  run with the icl file as program argument, and opens the file in
            a new instance of Clean.

            Opening in an existing instance of Clean is unfortunately not possible in wine.
