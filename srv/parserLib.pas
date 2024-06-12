unit parserLib;
{$INCLUDE defs.inc }
{$I NoRTTI.inc}

interface

uses
  strutils, sysutils, classes, types, windows,
  {$IFNDEF USE_MORMOT_COLLECTIONS}
  Generics.Collections,
  {$ELSE USE_MORMOT_COLLECTIONS}
  mormot.core.collections,
  {$ENDIF USE_MORMOT_COLLECTIONS}
  serverLib;

type

  TParameter = record
    k: String;
    v: String;
    full: String;
  end;

 {$IFDEF USE_MORMOT_COLLECTIONS}
  TParsVal = IKeyValue<String, String>;
 {$ELSE}
  TParsVal = Tdictionary<String, String>;
 {$ENDIF ~USE_MORMOT_COLLECTIONS}

  TPars2 = class
   private
    fD2: TParsVal;
    fA: array of TParameter;
    fCount: Integer;
   public
    constructor create;
    destructor  destroy; OverRide;
    procedure Add(const s: String);
    procedure Delete(idx: Integer);
    function  get(idx: Integer): String;
    function  getNames(idx: Integer): String;
    procedure setItem(idx: Integer; s: String);
    procedure clear;
    function  TryGetValue(const k: String; var v: String): Boolean;
    function  ContainsKey(const k: String): Boolean;
    function  toArray: TStringDynArray;
    property  count: Integer read fCount;
    property  Items[Index: Integer]: String read Get write setItem; default;
    property  names[Index: Integer]: String read GetNames;
    property  d2: TParsVal read fD2;
  end;


//  TPars = TStringList;
  TPars = TPars2;

  TmacroCB = function(fs: TFileServer; const fullMacro: UnicodeString; pars: TPars; cbData: pointer): UnicodeString;
  EtplError = class(Exception)
    pos, row, col: integer;
    code: string;
    constructor Create(const msg, code:string; row,col:integer);
   end;
const
  MARKER_OPEN = '{.';
  MARKER_CLOSE = '.}';
  MARKER_SEP = '|';
  MARKER_QUOTE = '{:';
  MARKER_UNQUOTE = ':}';
  MARKERS: array [0..4] of string = ( MARKER_OPEN, MARKER_CLOSE, MARKER_SEP, MARKER_QUOTE, MARKER_UNQUOTE );

  AMARKER_OPEN = RawByteString('{.');
  AMARKER_CLOSE = RawByteString('.}');
  AMARKER_SEP = RawByteString('|');
  AMARKER_QUOTE = RawByteString('{:');
  AMARKER_UNQUOTE = RawByteString(':}');
  AMARKERS: array [0..4] of RawByteString = ( MARKER_OPEN, MARKER_CLOSE, MARKER_SEP, MARKER_QUOTE, MARKER_UNQUOTE );

function isAnyMacroIn(const s: RawByteString): Boolean; inline;
function anyMacroMarkerIn(const s:string):boolean;
function findMacroMarker(const s: string; ofs:integer=1): integer;
procedure applyMacrosAndSymbols(fs: TFileServer; var txt: UnicodeString; cb: TmacroCB; cbData: pointer; removeQuotings: Boolean=TRUE);

function macroQuote(s:string):string;
function macroDequote(s:string):string;

implementation
uses
  srvUtils, HSLib;

const
  MAX_RECUR_LEVEL = 50;
type
  TparserIdsStack = array [1..MAX_RECUR_LEVEL] of string;

constructor EtplError.create(const msg, code:string; row, col:integer);
begin
inherited create(msg);
self.row:=row;
self.col:=col;
self.code:=code;
end;

constructor TPars2.create;
begin
  fCount := 0;
 {$IFNDEF USE_MORMOT_COLLECTIONS}
  fD2 := TParsVal.Create;
 {$ELSE USE_MORMOT_COLLECTIONS}
  fD2 := Collections.NewKeyValue<String, String>;
 {$ENDIF USE_MORMOT_COLLECTIONS}
  setLength(fA, 0);
end;

destructor TPars2.destroy;
begin
  {$IFNDEF USE_MORMOT_COLLECTIONS}
  fD2.Free;
  {$ELSE USE_MORMOT_COLLECTIONS}
  fD2 := NIL;
  {$ENDIF USE_MORMOT_COLLECTIONS}
  SetLength(fA, 0);
  fCount := 0;
end;

procedure TPars2.Add(const s: String);
var
  i, idx: Integer;
begin
  idx := Length(fA);
  SetLength(fA, idx+1);
  fCount := idx+1;
  fA[idx].full := s;
  i := AnsiPos('=', s);
  if (i > 0) then
    begin
      fA[idx].k := copy(s, 1, i-1);
      fA[idx].v := copy(s, i+1, length(s))
    end
   else
    begin
//      fA[idx].k := s;
      fA[idx].k := '';
      fA[idx].v := '';
    end;
  if fA[idx].k > '' then
  {$IFNDEF USE_MORMOT_COLLECTIONS}
    fD2.AddOrSetValue(fA[idx].k, fA[idx].v);
  {$ELSE USE_MORMOT_COLLECTIONS}
    fD2[fA[idx].k] := fA[idx].v;
  {$ENDIF USE_MORMOT_COLLECTIONS}
end;

procedure TPars2.Delete(idx: Integer);
var
  I: Integer;
begin
  if idx >= fCount then
    Exit;
  if fA[idx].k > '' then
    fD2.Remove(fA[idx].k);
  if idx < (fCount-1) then
    for I := idx to fCount-2 do
      fA[i] := fA[i+1];
  dec(fCount);
  SetLength(fA, fCount);
end;

function TPars2.get(idx: Integer): String;
begin
  Result := fA[idx].full;
end;

function TPars2.getNames(idx: Integer): String;
begin
  Result := fA[idx].k;
end;

procedure TPars2.setItem(idx: Integer; s: String);
var
  k, v: string;
  i: Integer;
begin
  i := AnsiPos('=', s);
  if (i > 0) then
    begin
      k := copy(s, 1, i-1);
      v := copy(s, i+1, length(s))
    end
   else
    begin
//      k := s;
      k := '';
      v := '';
    end;

  if k = fA[idx].k then
    begin
      if k > '' then
//        fD.AddOrSetValue(k, v);
        fD2[k] := v;
    end
   else
    begin
      if fA[idx].k > '' then
        fD2.Remove(fA[idx].k);
      if k > '' then
        fD2.Add(k, v);
      fA[idx].k := k;
    end;

  fA[idx].v := v;
  fA[idx].full := s;
end;

function TPars2.TryGetValue(const k: String; var v: String): Boolean;
begin
  Result := fD2.TryGetValue(k, v);
end;

function TPars2.ContainsKey(const k: String): Boolean;
begin
  Result := fD2.ContainsKey(k);
end;

procedure TPars2.clear;
begin
  fCount := 0;
  SetLength(fA, 0);
  fD2.clear;
end;

function TPars2.ToArray: TStringDynArray;
var
  i: integer;
begin
  if Length(fA) = 0 then
    Exit(NIL);
  try
    setLength(result, Length(fA));
      for i:=0 to Length(fA)-1 do
        result[i] := fA[i].full;
  except
    result:=NIL
    end
end; // ToArray


procedure applyMacrosAndSymbols2(fs: TFileServer; var txt: UnicodeString; cb: TmacroCB; cbData: Pointer; var idsStack: TparserIdsStack; recurLevel: integer=0);
const
  // we don't track SEPs, they are handled just before the callback
  QUOTE_ID = 0;   // QUOTE must come before OPEN because it is a substring
  UNQUOTE_ID = 1;
  OPEN_ID = 2;
  CLOSE_ID = 3;
  MAX_MARKER_ID = 3;

  function alreadyRecurredOn(const s: String): Boolean;
  var
    i: integer;
  begin
    //result := TRUE;
    if recurLevel > 1 then
      for i:=recurLevel downto 1 do
        if sameText(s, idsStack[i]) then
          exit(True);
    result:=FALSE;
  end; // alreadyRecurredOn

  procedure handleSymbols();
  var
    b, e, l : integer;
    s, newS: UnicodeString;
  begin
    e := 0;
    l := length(txt);
    while e < l do
    begin
    // search for next symbol
      b := posEx('%', txt, e+1);
      if b = 0 then
        break;
      e := b+1;
      if txt[e] = '%' then
      begin    // we don't accept %% as a symbol. so, restart parsing from the second %
        e := b;
        continue;
      end;
      if not (txt[e] in ['_','a'..'z','A'..'Z']) then
        continue; // first valid character
      while (e < l) and (txt[e] in ['0'..'9','a'..'z','A'..'Z','-','_']) do
        inc(e);
      if txt[e] <> '%' then
        continue;
      // found!
      s := substr(txt, b, e);
      if alreadyRecurredOn(s) then
        continue; // the user probably didn't meant to create an infinite loop

      newS := cb(fs, s, NIL, cbData);
      if s = newS then
        continue;

      idsStack[recurLevel]:=s; // keep track of what we recur on
      // apply translation, and eventually recur
      try
        applyMacrosAndSymbols2(fs, newS, cb, cbData, idsStack, recurLevel);
       except
      end;
      idsStack[recurLevel]:='';
      inc(e, replace(txt, newS, b, e));
      l := length(txt);
    end;
  end; // handleSymbols

  procedure handleMacros();
  var
    pars: TPars;

    function expand(from, to_:integer):integer;
    var
      s, fullMacro: UnicodeString;
      i, o, q, u: integer;
    begin
      result:=0;
      fullMacro := substr(txt, from+length(MARKER_OPEN), to_-length(MARKER_CLOSE));
      if alreadyRecurredOn(fullMacro) then
        exit; // the user probably didn't meant to create an infinite loop

    // let's find the SEPs to build 'pars'
      pars.clear();
      i := 1; // char pointer from where we shall copy the macro parameter
      o := 0;
      q := posEx(MARKER_QUOTE, fullMacro); // q points to _QUOTE
      repeat
        o := posEx(MARKER_SEP, fullMacro, o+1);
        if o = 0 then
          break;
        if (q > 0) and (q < o) then // this SEP is possibly quoted
        begin
        // update 'q' and 'u'
          repeat
          u := posEx(MARKER_UNQUOTE, fullMacro, q);
          if u = 0 then
            exit; // macro quoting not properly closed
          q:=posEx(MARKER_QUOTE, fullMacro, q+1); // update q for next cycle
          // if we find other _QUOTEs before _UNQUOTE, then they are stacked, and we must go through the same number of both markers
          while (q > 0) and (q < u) do
            begin
              u := posEx(MARKER_UNQUOTE, fullMacro, u+1);
              if u = 0 then
                exit; // macro quoting not properly closed
              q := posEx(MARKER_QUOTE, fullMacro, q+1);
            end;
          until (q = 0) or (o < q);
        // eventually skip this chunk of string
        if o < u then
          begin // yes, this SEP is quoted
          o:=u;
          continue;
          end;
        end;
        // ok, that's a valid SEP, so we collect this as a parameter
        pars.add(substr(fullMacro, i, o-1));
        i:=o+length(MARKER_SEP);
      until false;
      pars.add(substr(fullMacro, i, length(fullMacro))); // last piece
      // ok, 'pars' has now been built

      // do the call, recur, and replace with the result
      s := cb(fs, fullMacro, pars, cbData);
      idsStack[recurLevel] := fullMacro; // keep track of what we recur on
      if s > '' then
      try
        try
          applyMacrosAndSymbols2(fs, s, cb, cbData, idsStack, recurLevel)
         except
        end;
       finally
        idsStack[recurLevel]:=''
      end;
      result := replace(txt, s, from, to_);
    end; // expand

  const
    ID2TAG: array [0..MAX_MARKER_ID] of string = (MARKER_QUOTE, MARKER_UNQUOTE, MARKER_OPEN, MARKER_CLOSE);
  type
    TstackItem = record
      pos: integer;
      row, col: word;
      quote: boolean;
      end;
  var
    i, lastNL, row, m, t: integer;
    stack: array of TstackItem;
    Nstack: integer;
  begin
  setLength(stack, length(txt) div length(MARKER_OPEN)); // it will never need more than this
  Nstack:=0;
  pars := TPars.Create;
  try
    i:=1;
    row:=1;
    lastNL:=0;
    while i <= length(txt) do
      begin
      if txt[i] = #10 then
        begin
        inc(row);
        lastNL:=i;
        end;
      for m:=0 to MAX_MARKER_ID do
        begin
        if not strAt(txt, ID2TAG[m], i) then continue;
        case m of
          QUOTE_ID,
          OPEN_ID:
            begin
            if (m = OPEN_ID) and (Nstack > 0) and stack[Nstack-1].quote then continue; // don't consider quoted OPEN markers
            stack[Nstack].pos:=i;
            stack[Nstack].quote:= m=QUOTE_ID;
            stack[Nstack].row:=row;
            stack[Nstack].col:=i-lastNL;
            inc(Nstack);
            end;
          CLOSE_ID:
            begin
            if Nstack = 0 then
              raise EtplError.create('unmatched marker', copy(txt,i,30), row, i-lastNL);
            if (Nstack > 0) and stack[Nstack-1].quote then continue; // don't consider quoted CLOSE markers
            t:=length(MARKER_CLOSE);
            inc(i, t-1+expand(stack[Nstack-1].pos, i+t-1));
            dec(Nstack);
            end;
          UNQUOTE_ID:
            begin
            if (Nstack = 0) or not stack[Nstack-1].quote then continue;
            dec(Nstack);
            end;
          end;
        end;//for
      inc(i);
      end;
   finally
    pars.free
  end;
  if Nstack > 0 then
    with stack[Nstack-1] do
      raise EtplError.create('unmatched marker', copy(txt,pos,30), row, col)
  end; // handleMacros

begin
  if recurLevel > MAX_RECUR_LEVEL then
    exit;
  inc(recurLevel);
  handleSymbols();
  handleMacros();
end; //applyMacrosAndSymbols2

procedure applyMacrosAndSymbols(fs: TFileServer; var txt: UnicodeString; cb:TmacroCB; cbData:pointer; removeQuotings:boolean=TRUE);
var
  idsStack: TparserIdsStack;
begin
  enforceNUL(txt);
  applyMacrosAndSymbols2(fs, txt, cb, cbData, idsStack);
  if removeQuotings then
    txt := xtpl(txt, [MARKER_QUOTE, '', MARKER_UNQUOTE, ''])
end;

function findMacroMarker(const s:string; ofs:integer=1):integer;
begin result:=reMatch(s, '\{[.:]|[.:]\}|\|', 'm!', ofs) end;

function isAnyMacroIn(const s: RawByteString): Boolean; inline;
begin
  result := pos(AMARKER_OPEN, s) > 0
end;

function anyMacroMarkerIn(const s:string):boolean;
begin result:=findMacroMarker(s) > 0 end;

function isMacroQuoted(const s:string):boolean;
begin result:=ansiStartsStr(MARKER_QUOTE, s) and ansiEndsStr(MARKER_UNQUOTE, s) end;

function macroQuote(s:string):string;
var
  t: string;
begin
  enforceNUL(s);
if not anyMacroMarkerIn(s) then
  begin
  result:=s;
  exit;
  end;
// an UNQUOTE would invalidate our quoting, so let's encode any of it
t:=MARKER_UNQUOTE;
replace(t, '&#'+intToStr(charToUnicode(t[1]))+';', 1,1);
result:=MARKER_QUOTE+xtpl(s, [MARKER_UNQUOTE, t])+MARKER_UNQUOTE
end; // macroQuote

function macroDequote(s:string):string;
begin
result:=s;
s:=trim(s);
if isMacroQuoted(s) then
  result:=copy(s, length(MARKER_QUOTE)+1, length(s)-length(MARKER_QUOTE)-length(MARKER_UNQUOTE) );
end; // macroDequote


end.
