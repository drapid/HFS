## Introduction
You can use HFS (HTTP File Server) to send and receive files.
It's different from classic file sharing because it uses web technology.
It also differs from classic web servers because it's very easy to use and runs "right out-of-the box".

The virtual file system will allow you to easily share even one single file.


http://rejetto.com/hfs/

## Dev notes
Initially developed in 2002 with Delphi 6, now with Delphi 10.3.3 (Community Edition).
Icons are generated at http://fontello.com/ . Use fontello.json for further modifications.

For the default template we are targeting compatibility with Chrome 49 as it's the latest version running on Windows XP.

Modification:
Uses for.rnq from R&Q
All images are PNG with alpha-channel
New format for VFS saving (ZIP file with JSON and images as separate files)

Now it can be build with full unicode support and in X64.
<img src="https://rnq.ru/forum/attachment/1977" alt="Unicode">

## Libs used
- [ICS v8.64](http://www.overbyte.be) by François PIETTE 
- [For.RnQ](https://github.com/drapid/rnq/tree/master/for.RnQ)
- [Synopse mORMot2](https://github.com/synopse/mORMot2)
