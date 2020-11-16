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
  system.Generics.Collections,
  OverbyteIcsWSocket, OverbyteIcshttpProt,
  hslib, srvConst, srvClassesLib;

type
  Tip2av = Tdictionary<string,Tdatetime>;
  TantiDos = class
    const MAX_CONCURRENTS = 3;
  class var
    folderConcurrents: integer;
    ip2availability: Tip2av;
    class constructor Create;
  protected
    accepted: boolean;
    Paddress: string;
  public
    constructor create;
    destructor Destroy; override;
    function accept(conn:ThttpConn; address:string=''):boolean;
    end;


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
    class function createURL(url:string):ThttpClient;
    end;



implementation

uses
  windows, dateUtils, forms, ansiStrings,
  RDFileUtil, RDUtils,
  utilLib, hfsGlobal, hfsVars,
  srvUtils, srvVars;


class constructor TantiDos.Create;
begin
  ip2availability := NIL;
  folderConcurrents := 0;
end;

constructor TantiDos.create();
begin
accepted:=FALSE;
end;

function TantiDos.accept(conn:ThttpConn; address:string=''):boolean;

  procedure reject();
  resourcestring
    MSG_ANTIDOS_REPLY = 'Please wait, server busy';
  begin
  conn.reply.mode:=HRM_OVERLOAD;
  conn.addHeader(ansistring('Refresh: '+intToStr(1+random(2)))); // random for less collisions
  conn.reply.body:=UTF8Encode(MSG_ANTIDOS_REPLY);
  end;

begin
if address= '' then
  address:=conn.address;
if ip2availability = NIL then
  ip2availability:=Tip2av.create();
try
  if ip2availability.ContainsKey(address) then
   if ip2availability[address] > now() then // this specific address has to wait?
    begin
    reject();
    exit(FALSE);
    end;
except
  end;
if folderConcurrents >= MAX_CONCURRENTS then   // max number of concurrent folder loading, others are postponed
  begin
  reject();
  exit(FALSE);
  end;
inc(folderConcurrents);
Paddress:=address;
ip2availability.AddOrSetValue(address, now()+1/HOURS);
accepted:=TRUE;
Result:=TRUE;
end;

destructor TantiDos.Destroy;
var
  pair: Tpair<string,Tdatetime>;
  t: Tdatetime;
begin
if not accepted then
  exit;
t:=now();
if folderConcurrents = MAX_CONCURRENTS then // serving multiple addresses at max capacity, let's give a grace period for others
  ip2availability[Paddress]:=t + 1/SECONDS
else
  ip2availability.Remove(Paddress);
dec(folderConcurrents);
// purge leftovers
 for pair in ip2availability do
  if pair.Value < t then
    ip2availability.Remove(pair.Key);
end;

class function ThttpClient.createURL(url:string):ThttpClient;
begin
if startsText('https://', url)
and not httpsCanWork() then
  exit(NIL);
result:=ThttpClient.Create(NIL);
result.URL:=url;
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



end.
