{
Copyright (C) 2002-2020  Massimo Melina (www.rejetto.com)

This file is part of HFS ~ HTTP File Server.

    HFS is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    HFS is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with HFS; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
}
{$INCLUDE defs.inc }
unit classesLib;
{$I NoRTTI.inc}

interface

uses
  iniFiles, types, strUtils, sysUtils, classes,
 {$IFDEF FMX}
  ics.fmx.OverbyteIcsWSocket, ics.fmx.OverbyteIcshttpProt,
 {$ELSE ~FMX}
  OverbyteIcsWSocket, OverbyteIcshttpProt,
 {$ENDIF FMX}
  hslib, srvConst, srvClassesLib;

type

  TperIp = class // for every different address, we have an object of this class. These objects are never freed until hfs is closed.
   public
    limiter: TspeedLimiter;
    customizedLimiter: boolean;
    constructor create();
    destructor Destroy; override;
   end;

  ThttpClient = class(TSslHttpCli)
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; OverRide;
    class function createURL(const url: String): ThttpClient;
   end;

  function objByIP(const ip: String): TperIp;

implementation

uses
  windows, dateUtils,
  OverbyteIcsSslBase,
 {$IFDEF FMX}
  FMX.Forms,
 {$ELSE ~FMX}
  Forms,
 {$ENDIF FMX}
  ansiStrings,
  RDFileUtil, RDUtils,
  utilLib, hfsGlobal, hfsVars,
  srvUtils, srvVars;


class function ThttpClient.createURL(const url: String): ThttpClient;
begin
  if startsText('https://', url)
   and not httpsCanWork() then
    exit(NIL);
  result := ThttpClient.Create(NIL);
  result.URL := url;
end;

constructor ThttpClient.create(AOwner: TComponent);
begin
  inherited;
  followRelocation:=TRUE;
  agent:=HFS_HTTP_AGENT;
  SslContext := TSslContext.Create(NIL);
end; // create

destructor ThttpClient.Destroy;
begin
  SslContext.free;
  SslContext:=NIl;
  inherited destroy;
end;

constructor TperIp.create();
begin
  limiter:=TspeedLimiter.create();
  srv.limiters.add(limiter);
end;

destructor TperIp.Destroy;
begin
  srv.limiters.remove(limiter);
  limiter.free;
end;

function objByIP(const ip: String): TperIp;
var
  i: integer;
begin
  i := ip2obj.indexOf(ip);
  if i < 0 then
    i := ip2obj.add(ip);
  if ip2obj.objects[i] = NIL then
    ip2obj.objects[i] := TperIp.create();
  result := ip2obj.objects[i] as TperIp;
end; // objByIP



end.
