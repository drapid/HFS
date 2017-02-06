// this file comes from http://fastcode.sf.net/ updated to 3 Jan 2007

unit AnsiStringReplaceJOHIA32Unit13;

interface

{$R-,Q-}

uses
  Windows, SysUtils, StrUtils;

{Equivalent of StringReplace for Non Multi Byte Character Sets}
function stringReplace(const Str, Old, New: AnsiString;
                                   Flags: TReplaceFlags): AnsiString;

implementation

{$IFNDEF Delphi2005Plus}
  {$I D7PosEx.inc}
{$ENDIF}

{Size = 1005 Bytes + 256 Byte Lookup Table + 4 Byte Code Page = 1265 Bytes}

function stringReplace(const Str, Old, New: AnsiString;
                                   Flags: TReplaceFlags): AnsiString;
const
  srCodePage    : UINT = 0; {Active Windows CodePage}
  AnsiUpcase    : string[255] = ''; {256 Character Upcase Lookup Table}
  StaticBufSize = 16; {Static Buffer Size}
  StaticBufMem  = StaticBufSize * SizeOf(Integer); {Static Buffer Memory Use}
var
  StaticBuffer  : array[0..StaticBufSize-1] of Integer;
  SaveStr       : Integer;
  SaveOld       : Integer;
  SaveNew       : Integer;
  StrLen        : Integer;
  OldLen        : Integer;
  NewLen        : Integer;
  Buffer        : Integer;
  BufSize       : Integer;
  Matches       : Integer;
  Start         : Integer;
  PosExFunc     : Integer;
asm
  push   ebx                   {Save Registers}
  push   edi
  push   esi
  test   eax, eax              {Str = nil?}
  mov    SaveStr, eax          {Save Str}
  mov    SaveOld, edx          {Save Old}
  mov    SaveNew, ecx          {Save New}
  jz     @@NilResult           {Str = nil, Exit Setting Result = ''}
  test   edx, edx              {OldPatterm = nil?}
  mov    ebx, [eax-4]          {Length(Str)}
  jz     @@SetResult           {OldPatterm = nil, Exit Setting Result = Str}
  mov    edi, [edx-4]          {Length(Old)}
  test   edi, edi              {OldLen = 0?}
  jz     @@SetResult           {Yes, Exit Setting Result = Str}
  cmp    ebx, edi              {StrLen < OldLen?}
  jb     @@SetResult           {Yes, Exit Setting Result = Str}
  xor    esi, esi              {Set NewLen = 0}
  test   ecx, ecx              {New = nil?}
  jz     @@GotLengths          {Yes, NewLen = 0}
  mov    esi, [ecx-4]          {NewLen}
@@GotLengths:
  lea    eax, PosEx            {Default PosExFunction = system.PosEx}
  test   Flags, 2              {rfIgnoreCase in Flags?}
  mov    PosExFunc, eax
  jz     @@TestFlags           {No, Use system.PosEx Function}
  lea    eax, @@AnsiPosExIC    {Change PosEx Function to AnsiPosExIC}
  mov    PosExFunc, eax        {Store PosEx Function}
  call   GetACP                {Get Active Code Page}
  cmp    eax, srCodePage       {Code Page Changed or Not Set?}
  je     @@TestFlags           {No, Already Got AnsiUpcase Lookup Table}
  mov    srCodePage, eax       {Save CodePage}
  lea    eax, AnsiUpcase       {Setup AnsiUpcase Lookup Table}
  xor    ecx, ecx
@@AnsiUpcaseLoop:              {Set each Character in Table}
  mov    [eax+ecx], cl         { to its own Character Position}
  inc    ecx
  test   cl, cl
  jnz    @@AnsiUpcaseLoop      {Repeat 256 times}
  push   ecx                   {256}
  push   eax                   {srCodePage}
  call   CharUpperBuffA        {Convert AnsiUpcase Table to Uppercase}
@@TestFlags:
  test   Flags, 1              {rfReplaceAll in Flags}
  jz     @@ReplaceFirstOnly    {No, Replace First Occurance Only}
  cmp    edi, 1                {OldLen = 1?}
  jne    @@NotSingleChar       {No, Not Single Character Replacement}
  cmp    esi, 1                {NewLen = 1?}
  jne    @@NotSingleChar       {No, Not Single Character Replacement}
  mov    eax, Result           {@Result}
  mov    edx, ebx              {StrLen(Remainder)}
  call   system.@LStrSetLength {Set Result Length to StrLen}
  mov    eax, SaveStr          {Str}
  mov    edx, Result           {@Result}
  mov    edx, [edx]            {Result}
  mov    edi, edx              {Save Result}
  mov    ecx, ebx              {StrLen}
  call   Move                  {Result = Str}
  mov    eax, SaveOld          {Old}
  mov    edx, SaveNew          {New}
  movzx  ecx, [eax]            {Old[1]}
  movzx  edx, [edx]            {New[1]}
  test   Flags, 2              {rfIgnoreCase in Flags}
  jz     @@CharLoopCS          {No, Case Sensitive}
  movzx  ecx, [ecx+AnsiUpcase] {AnsiUpcase(Old[1])}

@@CharLoopIC:                  {Replace All Ignoring Case}
  dec    ebx                   {Dec(Remainder)}
  movzx  eax, [edi+ebx]        {Next Char of Result}
  movzx  eax, [eax+AnsiUpcase] {Convert to Uppercase}
  cmp    eax, ecx              {Match Found?}
  jne    @@CharCheckIC         {No, Ready for Next Char}
  mov    [edi+ebx], dl         {Yes, Replace Char}
@@CharCheckIC:
  test   ebx, ebx              {Remainder = 0?}
  jnz    @@CharLoopIC          {No, Loop}
  jmp    @@Done                {Finished}

@@CharLoopCS:                  {Case Sensitive Replace All}
  dec    ebx                   {Dec(Remainder)}
  movzx  eax, [edi+ebx]        {Next Char of Result}
  cmp    eax, ecx              {Match Found?}
  jne    @@CharCheckCS         {No, Ready for Next Char}
  mov    [edi+ebx], dl         {Yes, Replace Char}
@@CharCheckCS:
  test   ebx, ebx              {Remainder = 0?}
  jnz    @@CharLoopCS          {No, Loop}
  jmp    @@Done                {Finished}

@@NilResult:
  mov    eax, Result           {Result}
  call   system.@LStrClr       {Result := ''}
  jmp    @@Done                {Finished}

@@SetResult:
  test   ebx, ebx              {StrLen = 0?}
  jz     @@NilResult           {Yes, Return Result = nil}
  mov    edx, SaveStr          {Str}
  mov    eax, Result           {Result}
  call   system.@LStrAsg       {Result := S}
  jmp    @@Done                {Finished}

{function AnsiPosExIC(const SubStr, S: string; Offset: Integer): Integer;}
@@AnsiPosExIC:
  push   ebx
  push   esi
  push   edx                   {@Str}
  mov    esi, ecx
  mov    ecx, [edx-4]          {Length(Str) (S<>nil)}
  mov    ebx, [eax-4]          {Length(SubStr) (SubStr<>nil)}
  add    ecx, edx
  sub    ecx, ebx              {Max Start Pos for a Full Match}
  lea    edx, [edx+esi-1]      {Set Start Position}
  cmp    edx, ecx
  jg     @@NotFound            {StartPos > Max Start Pos}
  cmp    ebx, 1                {Length(SubStr)}
  jle    @@SingleChar          {Length(SubStr) <= 1}
  push   edi
  push   ebp
  lea    edi, [ebx-2]          {Length(SubStr) - 2}
  mov    esi, eax
  push   edi                   {Save Remainder to Check = Length(SubStr) - 2}
  push   ecx                   {Save Max Start Position}
  lea    edi, AnsiUpcase       {Uppercase Lookup Table}
  movzx  ebx, [eax]            {Search Character = 1st Char of SubStr}
  movzx  ebx, [edi+ebx]        {Convert to Uppercase}
@@Loop:                        {Loop Comparing 2 Characters per Loop}
  movzx  eax, [edx]            {Get Next Character}
  movzx  eax, [edi+eax]        {Convert to Uppercase}
  cmp    eax, ebx
  jne    @@NotChar1
  mov    ebp, [esp+4]          {Remainder to Check}
@@Char1Loop:                                  
  movzx  eax, [esi+ebp]
  movzx  ecx, [edx+ebp]
  movzx  eax, [edi+eax]        {Convert to Uppercase}
  movzx  ecx, [edi+ecx]        {Convert to Uppercase}
  cmp    eax, ecx
  jne    @@NotChar1
  movzx  eax, [esi+ebp+1]
  movzx  ecx, [edx+ebp+1]
  movzx  eax, [edi+eax]        {Convert to Uppercase}
  movzx  ecx, [edi+ecx]        {Convert to Uppercase}
  cmp    eax, ecx
  jne    @@NotChar1
  sub    ebp, 2
  jnc    @@Char1Loop
  pop    ecx
  pop    edi
  pop    ebp
  pop    edi
  jmp    @@SetResult2
@@NotChar1:
  movzx  eax, [edx+1]          {Get Next Character}
  movzx  eax, [edi+eax]        {Convert to Uppercase}
  cmp    bl, al
  jne    @@NotChar2
  mov    ebp, [esp+4]          {Remainder to Check}
@@Char2Loop:
  movzx  eax, [esi+ebp]
  movzx  ecx, [edx+ebp+1]
  movzx  eax, [edi+eax]        {Convert to Uppercase}
  movzx  ecx, [edi+ecx]        {Convert to Uppercase}
  cmp    eax, ecx
  jne    @@NotChar2
  movzx  eax, [esi+ebp+1]
  movzx  ecx, [edx+ebp+2]
  movzx  eax, [edi+eax]        {Convert to Uppercase}
  movzx  ecx, [edi+ecx]        {Convert to Uppercase}
  cmp    eax, ecx
  jne    @@NotChar2
  sub    ebp, 2
  jnc    @@Char2Loop
  pop    ecx
  pop    edi
  pop    ebp
  pop    edi
  jmp    @@CheckResult         {Check Match is within String Data}
@@NotChar2:
  add    edx, 2
  cmp    edx, [esp]            {Compate to Max Start Position}
  jle    @@Loop                {Loop until Start Pos > Max Start Pos}
  pop    ecx                   {Dump Start Position}
  pop    edi                   {Dump Remainder to Check}
  pop    ebp
  pop    edi
  jmp    @@NotFound
@@SingleChar:
  jl     @@NotFound            {Needed for Zero-Length Non-NIL Strings}
  lea    esi, AnsiUpcase
  movzx  ebx, [eax]            {Search Character = 1st Char of SubStr}
  movzx  ebx, [esi+ebx]        {Convert to Uppercase}
@@CharLoop:
  movzx  eax, [edx]
  movzx  eax, [esi+eax]        {Convert to Uppercase}
  cmp    eax, ebx
  je     @@SetResult2
  movzx  eax, [edx+1]
  movzx  eax, [esi+eax]        {Convert to Uppercase}
  cmp    eax, ebx
  je     @@CheckResult
  add    edx, 2
  cmp    edx, ecx
  jle    @@CharLoop
@@NotFound:
  xor    eax, eax
  pop    edx
  pop    esi
  pop    ebx
  ret
@@CheckResult:                 {Check Match is within String Data}
  cmp    edx, ecx
  jge    @@NotFound
  inc    edx                   {OK - Adjust Result}
@@SetResult2:                  {Set Result Position}
  pop    ecx                   {@Str}
  pop    esi
  pop    ebx
  neg    ecx
  lea    eax, [edx+ecx+1]
  ret
{End of function AnsiPosExIC}

@@NotSingleChar:               {Not a Single Character Replacement}
  mov    eax, SaveOld          {Old}
  mov    edx, SaveStr          {Str}
  mov    ecx, 1                {Initial PosEx Offset = 1}
  call   PosExFunc             {Call PosEx Function}
  test   eax, eax              {Match Found?}
  jz     @@SetResult           {No, Result = Str}
  mov    ecx, eax              {Yes, Save Match Position}
  mov    StrLen, ebx           {StrLen = Length(Str)}
  mov    OldLen, edi           {OldLen = Length(Old)}
  mov    NewLen, esi           {NewLen = Length(New)}
  lea    edx, StaticBuffer     {Static Buffer Address}
  mov    BufSize, StaticBufSize{Initial Buffer Size}
  mov    Buffer, edx           {Set Buffer Address}
  xor    ebx, ebx              {Matches-1}
  mov    [edx], eax            {Buffer[0] = Match Position}
@@SearchLoop:
  inc    ebx                   {Matches}
  mov    eax, SaveOld          {Old}
  mov    edx, SaveStr          {Str}
  add    ecx, edi              {Inc(Match Position, OldLen)}
  call   PosExFunc             {PosEx(Old, Str, Match Position)}
  test   eax, eax              {Match Found?}
  mov    ecx, eax              {Match Position}
  jz     @@GotAllMatches       {No More Matches Found}
  cmp    ebx, BufSize          {Matches = BufSize?}
  je     @@BufferFull          {Create or Expand Dynamic Buffer}
@@SaveMatchPosition:           {Save Match Position}
  mov    eax, Buffer           {Buffer Address}
  mov    [eax+ebx*4], ecx      {Buffer[Matches] = Match Position}
  jmp    @@SearchLoop          {Repeat Until No More Matches Found}

@@BufferFull:                  {Create or Expand Dynamic Buffer}
  push   ecx                   {Save Match Position}
  mov    edx, ebx              {BufSize}
  shr    edx, 1                {Buffer Size / 2}
  lea    eax, [ebx+edx]        {Grow Buffer by 50%}
  mov    BufSize, eax          {Save Buffer Size}
  lea    edx, StaticBuffer     {Static Buffer Address}
  cmp    Buffer, edx           {Buffer = Static Buffer?}
  jne    @@Expand              {No, Expand Dynamic Buffer}
  shl    eax, 2                {BufSize * SizeOf(Integer)}
  call   system.@GetMem        {Create Dynamic Buffer}
  mov    Buffer, eax           {Save Dynamic Buffer Address}
  mov    edx, eax              {Dynamic Buffer Address}
  lea    eax, StaticBuffer     {Static Buffer Address}
  mov    ecx, StaticBufMem     {Static Buffer Size}
  call   Move                  {Copy Static Buffer Data into Dynamic Buffer}
  pop    ecx                   {Restore Match Position}
  jmp    @@SaveMatchPosition   {Save Match Position}
@@Expand:                      {Expand Dynamic Buffer}
  shl    eax, 2                {BufSize * SizeOf(Integer)}
  mov    edx, eax              {Buffer Size (Bytes)}
  lea    eax, Buffer           {Buffer Address}
  call   system.@ReAllocMem    {Increase Buffer Size by 50%}
  mov    Buffer, eax           {Save Buffer Address}
  pop    ecx                   {Restore Match Position}
  jmp    @@SaveMatchPosition   {Save Match Position}

@@GotAllMatches:               {All Match Positions Found}
  mov    edx, esi              {NewLen}
  sub    edx, edi              {NewLen - Oldlen}
  imul   edx, ebx              {Matches * (NewLen - OldLen)}
  add    edx, StrLen           {StrLen + (Matches * (NewLen - OldLen))}
  mov    eax, Result           {@Result}
  call   System.@LStrSetLength {Set Result Length}
  mov    esi, SaveStr          {Str}
  mov    edi, Result           {@Result}
  mov    edi, [edi]            {Result}
  mov    Matches, ebx          {Save Matches}
  mov    Start, 1              {Start = 1}
  xor    ebx, ebx              {Match = 0}
@@ReplaceLoop:                 {Replace Chars at Next Match Position}
  mov    eax, Buffer           {Buffer Address}
  mov    eax, [eax+ebx*4]      {Match Position = Buffer[Match]}
  inc    ebx                   {Increment Match for Next Loop}
  mov    ecx, eax              {Match Position}
  add    eax, OldLen           {Match Position + OldLen}
  sub    ecx, Start            {Count = Match Position - Start}
  mov    Start, eax            {Start = Match Position + OldLen}
  jz     @@Moved1              {If Count = 0, No Move Needed}
  push   ecx                   {Save Count}
  mov    eax, esi              {PStr}
  mov    edx, edi              {PRes}
  call   Move                  {Move(PStr^, PRes^, Count)}
  pop    ecx                   {Restore Count}
  add    edi, ecx              {Inc(PRes, Count)}
@@Moved1:
  add    ecx, OldLen           {Count + OldLen)}
  add    esi, ecx              {Inc(PStr, Count + OldLen)}
  mov    eax, SaveNew          {New}
  mov    edx, edi              {PRes}
  mov    ecx, NewLen           {NewLen}
  add    edi, ecx              {PRes + NewLen}
  call   Move                  {Move(New, PRes, NewLen)}
  cmp    ebx, Matches          {All Matches Processed}
  jne    @@ReplaceLoop         {No, Process Next Match}
  mov    ecx, StrLen           {StrLen}
  sub    ecx, Start            {Remainder = StrLen - Start}
  jb     @@Moved2              {No Move if Remainder < 0}
  mov    eax, esi              {PStr}
  mov    edx, edi              {PRes}
  inc    ecx                   {Remainder - 1}
  call   Move                  {Move(PStr, PRes, Remainder - 1)}
@@Moved2:
  mov    eax, Buffer           {Buffer Address}
  lea    edx, StaticBuffer     {Static Buffer Addres}
  cmp    eax, edx              {Buffer = Static Buffer}
  je     @@Done                {Yes, Finished}
  call   system.@FreeMem       {No, Delete Dynamic Buffer}
  jmp    @@Done                {Finished}

@@ReplaceFirstOnly:            {Replace First Occurance Only}
  mov    StrLen, ebx           {StrLen}
  mov    eax, SaveOld          {Old}
  mov    edx, SaveStr          {Str}
  mov    ecx, 1                {PosEx Offset = 1}
  call   PosExFunc             {Call PosEx Function}
  sub    eax, 1                {Match Position-1}
  jc     @@SetResult           {No Match, Result = Str}
  mov    ebx, eax              {Match, Save Match Position-1}
  mov    edx, StrLen           {StrLen}
  mov    eax, Result           {@Result}
  sub    edx, edi              {StrLen - OldLen}
  add    edx, esi              {StrLen - OldLen + NewLen}
  call   system.@LStrSetLength {SetLength(Result, StrLen-OldLen+NewLen)}
  cmp    edi, esi              {OldLen = NewLen?}
  jne    @@DiffLen             {No, Different Lengths}
  mov    eax, SaveStr          {Str}
  mov    edx, Result           {@Result}
  mov    edx, [edx]            {Result}
  mov    ecx, StrLen           {StrLen}
  lea    edi, [edx+ebx]        {Result + Match Position-1}
  call   Move                  {Result = Str}
  mov    eax, SaveNew          {New}
  mov    edx, edi              {Result + Match Position-1}
  mov    ecx, esi              {NewLen}
  jmp    @@FinalMove           {Perform Final Move then Finish}
@@DiffLen:
  mov    OldLen, edi           {OldLen}
  push   esi                   {NewLen}
  mov    edi, Result           {@Result}
  mov    esi, SaveStr          {Str}
  mov    edi, [edi]            {Result}
  mov    eax, esi              {Str}
  mov    edx, edi              {Result}
  mov    ecx, ebx              {Match Position-1}
  call   Move                  {Move(PStr^, PRes^, Match Position)}
  add    esi, ebx              {Str + Match Position-1}
  add    edi, ebx              {Result + Match Position-1}
  add    esi, OldLen           {Str + OldLen}
  mov    eax, SaveNew          {New}
  mov    edx, edi              {Result + Match Position-1}
  pop    ecx                   {NewLen}
  add    edi, ecx              {Result + Match Position-1 + NewLen}
  call   Move                  {Move(Pointer(New)^, PRes^, NewLen)}
  mov    ecx, StrLen           {StrLen}
  mov    eax, esi              {Str + OldLen}
  sub    ecx, ebx              {StrLen - Match Position-1}
  mov    edx, edi              {Result + Match Position-1 + NewLen}
  sub    ecx, OldLen           {StrLen - Match Position-1 - OldLen}
@@FinalMove:
  call   Move                  {Perform Final Move}

@@Done:
  pop    esi                   {Restore Registers}
  pop    edi
  pop    ebx
end;

end.
