unit GameLogic;

{$mode objfpc}{$H+}

interface

uses RayLib, SysUtils;

type
     TPlayer = record
      x,y : Integer; //текущие координаты
      animIndex: Integer;
      Solution : String; //список ходов пользователя
     end;

    TSklad = array of array of Char;

    //загрузить уровень и вернуть динамический массив
    function LoadLevel(levnom : Integer; var dynarr : TSklad):Boolean;
    function LoadLevel(levelfile : String; var dynarr : TSklad):Boolean;
    //сохранить уровень в указанный файл
    function SaveLevel(levelname : string):Boolean;
    //перейти на следующий уровень
    procedure Nextlevel;
    //проверить пройден ли уровень
    function CheckWin: Boolean;
    //сохранить прохождение
    procedure SaveSolution;
    //загрузить прохождеие
    function LoadSolution: Boolean;

    procedure MoveLeft; //переместиться влево
    procedure MoveRight; //переместиться вправо
    procedure MoveUp; //переместиться вверх
    procedure MoveDown; //переместиться вниз

    procedure uPlayerBack; //вернуть перемещение игрока
    procedure dPlayerBack; //вернуть перемещение игрока
    procedure lPlayerBack; //вернуть перемещение игрока
    procedure rPlayerBack; //вернуть перемещение игрока
    procedure uBoxBack;    //вернуть перемещение ящика
    procedure dBoxBack;    //вернуть перемещение ящика
    procedure lBoxBack;    //вернуть перемещение ящика
    procedure rBoxBack;    //вернуть перемещение ящика

    procedure ChangeMatrixWidth(aNewWidth : Integer);
    //изменить текущую ширину уровня
    procedure ChangeMatrixHeight(aNewHeight : Integer);
    //изменить текущую высоту уровня

var
    Sklad : TSklad;                //игровое поле
    FieldX, FieldY : Integer;      //размеры текущего уровня
    CurrLevel : Integer;           //№ текущего уровня
    Player : TPlayer;              //текущее состояние игрока
    LevelSolution : String;        //описание прохождения уровня

    //Переменные, необходимые для редактора
    LevelFileName : String;       //имя файла для сохранения
    CurrSymbol    : String;       //Текущий символ для вставки при клике мышкой
    CanDraw       : Boolean;
   // Log: TPHXLogger;

implementation

function LoadLevel(levnom: Integer; var dynarr: TSklad): Boolean;
var t : TextFile; //файл уровня
    i : Integer;  //счётчик
    s : String;
    currline : Integer; //счётчик строк
begin
 Result:=true;
 //проверим наличие файла уровня
 if not FileExists('data/levels/'+IntToStr(levnom)+'.xsb') then begin
  //файл отсутствует - устанавливаем отрицательный результат и выходим
  Result:=false;
  Exit;
 end;
 //обнуляем динамический массив
 for i:=0 to High(DynArr) do SetLength(DynArr[i],0);
 SetLength(DynArr,0);
 //обнуляем данные игрока
 Player.x:=0;
 Player.y:=0;
 Player.Solution:='';
 AssignFile(t,'data/levels/'+IntToStr(levnom)+'.xsb');
 Reset(t);
 currline:=0;
 repeat
  Inc(currline);
  ReadLN(t,s);
  SetLength(DynArr,currline);
  SetLength(DynArr[currline-1],Length(s));
  for i:=1 to Length(s) do begin
       DynArr[currline-1,i-1]:=s[i];
       case s[i] of
    '@','+': begin //координаты игрока
          Player.y:=currline-1;
          Player.x:=i-1;
        end;
   end;
  end;
 until EoF(t);
 LoadSolution;
end;

function LoadLevel(levelfile: String; var dynarr: TSklad): Boolean;
var t : TextFile; //файл уровня
    i : Integer;  //счётчик
    s : String;
    currline : Integer; //счётчик строк
begin
 Result:=true;
 //проверим наличие файла уровня
 if not FileExists(levelfile) then begin
  //файл отсутствует - устанавливаем отрицательный результат и выходим
  Result:=false;
  Exit;
 end;
 //обнуляем динамический массив
 for i:=0 to High(DynArr) do SetLength(DynArr[i],0);
 SetLength(DynArr,0);
 //обнуляем данные игрока
 Player.x:=0;
 Player.y:=0;
 Player.Solution:='';
 AssignFile(t,levelfile);
 Reset(t);
 currline:=0;
 repeat
  Inc(currline);
  ReadLN(t,s);
  SetLength(DynArr,currline);
  SetLength(DynArr[currline-1],Length(s));
  for i:=1 to Length(s) do begin
       DynArr[currline-1,i-1]:=s[i];
       case s[i] of
    '@','+': begin //координаты игрока
          Player.y:=currline-1;
          Player.x:=i-1;
        end;
   end;
  end;
 until EoF(t);
 LoadSolution;
end;

function SaveLevel(levelname: string): Boolean;
var t : TextFile; //файл уровня
    i : Integer;  //счётчик
    s : String;
    currline : Integer; //счётчик строк
begin
 Result:=false;
 AssignFile(t,levelname);
 Rewrite(t);
 for currline:=0 to High(Sklad) do begin
  s:='';
  for i:=0 to High(Sklad[currline])-1 do s:=s+Sklad[currline,i];
  WriteLn(t,s);
 end;
 CloseFile(t);
end;

procedure Nextlevel;
begin
 Player.animIndex := 2;
 Inc(CurrLevel); //увеличить на 1 счётчик уровней
 if not LoadLevel(CurrLevel, Sklad) then begin //пробуем загрузить уровень
  if CurrLevel=1 then
  begin;
   Writeln('Отсутствует файл уровня!');
   Exit; //отсутствует файл - выходим ничего не делая
  end
   else
   begin
   //закончились уровни - игра пройдена
   writeln('Поздравляем! Вы прошли все уровни!');
   CurrLevel:=0;
   Nextlevel;
  end;
 end;
end;

function CheckWin: Boolean;
var i,j : Integer;
begin
  result:=false;
  for i:=0 to High(Sklad) do
   for j:=0 to High(Sklad[i]) do if Sklad[i,j]='$' then Exit;
  result:=true;
end;

procedure SaveSolution;
var sol : TextFile;
begin
 AssignFile(sol,GetApplicationDirectory+('data/levels/'+IntToStr(CurrLevel)+'.sol'));
 //AssignFile(sol,ProgramDirectory+DirectorySeparator+'data'+DirectorySeparator+IntToStr(CurrLevel)+'.sol');
 Rewrite(sol);
 Write(sol,Player.Solution);
 Close(sol);
end;

function LoadSolution: Boolean;
var sol : TextFile;
begin
Result:=true;
LevelSolution:='';
//проверим наличие файла прохождения
if not FileExists(GetApplicationDirectory+('data/levels/'+IntToStr(CurrLevel)+'.sol')) then begin
 //файл отсутствует - устанавливаем отрицательный результат и выходим
 Result:=false;
 Exit;
end;
AssignFile(sol,GetApplicationDirectory+GetAppDir('data/levels/'+ IntToStr(CurrLevel)+'.sol'));
//AssignFile(sol,ProgramDirectory+DirectorySeparator+'data'+DirectorySeparator+IntToStr(CurrLevel)+'.sol');
Reset(sol);
Read(sol,levelsolution);
CloseFile(sol);
end;

procedure MoveLeft; //переместиться влево
begin
 Player.animIndex:=2;
  if Player.x=0 then Exit;//двигаться некуда

case Sklad[Player.y,Player.x-1] of
'#': Exit;//стена
' ': Begin //пусто

      if Sklad[Player.y,Player.x]='+' then Sklad[Player.y,Player.x]:='.'
       else Sklad[Player.y,Player.x]:=' ';
      Dec(Player.x); //уменьшить X координату игрока
      Sklad[Player.y,Player.x]:='@';
      Player.Solution:=Player.Solution+'l'; //записать ход в переменную
     end;
'.': Begin //место для ящика

      if Sklad[Player.y,Player.x]='+' then Sklad[Player.y,Player.x]:='.'
       else Sklad[Player.y,Player.x]:=' ';
      Dec(Player.x); //уменьшить X координату игрока
      Sklad[Player.y,Player.x]:='+';
      Player.Solution:=Player.Solution+'l'; //записать ход в переменную
     end;
'$': begin //ящик

      if Player.x<2 then exit;
      case Sklad[Player.y,Player.x-2] of
       ' ': begin //пусто
          Sklad[Player.y,Player.x-2]:='$';
          Sklad[Player.y,Player.x-1]:='@';
          if Sklad[Player.y,Player.x]='+' then Sklad[Player.y,Player.x]:='.'
            else Sklad[Player.y,Player.x]:=' ';
          Dec(Player.x);
          Player.Solution:=Player.Solution+'L';
            end;
       '.': begin //цель

               Sklad[Player.y,Player.x-2]:='*';
               Sklad[Player.y,Player.x-1]:='@';
               if Sklad[Player.y,Player.x]='+' then Sklad[Player.y,Player.x]:='.'
                 else Sklad[Player.y,Player.x]:=' ';
               Dec(Player.x);
               Player.Solution:=Player.Solution+'L';
            end;
      end;
     end;
'*': begin //ящик на цели
      if Player.x<2 then exit;
      case Sklad[Player.y,Player.x-2] of
       ' ': begin //пусто
          Sklad[Player.y,Player.x-2]:='$';
          Sklad[Player.y,Player.x-1]:='+';
          if Sklad[Player.y,Player.x]='+' then Sklad[Player.y,Player.x]:='.'
            else Sklad[Player.y,Player.x]:=' ';
          Dec(Player.x);
          Player.Solution:=Player.Solution+'L';
       end;
       '.': begin //цель
               Sklad[Player.y,Player.x-2]:='*';
               Sklad[Player.y,Player.x-1]:='+';
               if Sklad[Player.y,Player.x]='+' then Sklad[Player.y,Player.x]:='.'
                 else Sklad[Player.y,Player.x]:=' ';
               Dec(Player.x);
               Player.Solution:=Player.Solution+'L';
            end;
      end;
     end;
 end; Player.animIndex:=10;
end;

procedure MoveRight; //переместиться вправо
begin
  Player.animIndex:=2;
  if Player.x=High(Sklad[Player.y]) then Exit;//двигаться некуда
case Sklad[Player.y,Player.x+1] of
'#': Exit;//стена
' ': Begin //пусто
      if Sklad[Player.y,Player.x]='+' then Sklad[Player.y,Player.x]:='.'
       else Sklad[Player.y,Player.x]:=' ';
      Inc(Player.x); //увеличить X координату игрока
      Sklad[Player.y,Player.x]:='@';
      Player.Solution:=Player.Solution+'r'; //записать ход в переменную
     end;
'.': Begin //место для ящика
      if Sklad[Player.y,Player.x]='+' then Sklad[Player.y,Player.x]:='.'
       else Sklad[Player.y,Player.x]:=' ';
      Inc(Player.x); //увеличить X координату игрока
      Sklad[Player.y,Player.x]:='+';
      Player.Solution:=Player.Solution+'r'; //записать ход в переменную
     end;
'$': begin //ящик
      if Player.x>(High(Sklad[Player.Y])-2) then exit;
      case Sklad[Player.y,Player.x+2] of
       ' ': begin //пусто
          Sklad[Player.y,Player.x+2]:='$';
          Sklad[Player.y,Player.x+1]:='@';
          if Sklad[Player.y,Player.x]='+' then Sklad[Player.y,Player.x]:='.'
            else Sklad[Player.y,Player.x]:=' ';
          Inc(Player.x);
          Player.Solution:=Player.Solution+'R';
            end;
       '.': begin //цель
               Sklad[Player.y,Player.x+2]:='*';
               Sklad[Player.y,Player.x+1]:='@';
               if Sklad[Player.y,Player.x]='+' then Sklad[Player.y,Player.x]:='.'
                 else Sklad[Player.y,Player.x]:=' ';
               Inc(Player.x);
               Player.Solution:=Player.Solution+'R';
            end;
      end;
     end;
'*': begin //ящик на цели
      if Player.x>(High(Sklad[Player.Y])-2) then exit;
      case Sklad[Player.y,Player.x+2] of
       ' ': begin //пусто
          Sklad[Player.y,Player.x+2]:='$';
          Sklad[Player.y,Player.x+1]:='+';
          if Sklad[Player.y,Player.x]='+' then Sklad[Player.y,Player.x]:='.'
            else Sklad[Player.y,Player.x]:=' ';
          Inc(Player.x);
          Player.Solution:=Player.Solution+'R';
       end;
       '.': begin //цель
               Sklad[Player.y,Player.x+2]:='*';
               Sklad[Player.y,Player.x+1]:='+';
               if Sklad[Player.y,Player.x]='+' then Sklad[Player.y,Player.x]:='.'
                 else Sklad[Player.y,Player.x]:=' ';
               Inc(Player.x);
               Player.Solution:=Player.Solution+'R';
            end;
      end;
     end;
 end; Player.animIndex:=10;
end;


procedure MoveUp; //переместиться вверх
begin
 Player.animIndex:=2;
  if Player.y=0 then Exit;//двигаться некуда
case Sklad[Player.y-1,Player.x] of
'#': Exit;//стена
' ': Begin //пусто
      if Sklad[Player.y,Player.x]='+' then Sklad[Player.y,Player.x]:='.'
       else Sklad[Player.y,Player.x]:=' ';
      Dec(Player.y); //уменьшить вертикальную координату игрока
      Sklad[Player.y,Player.x]:='@';
      Player.Solution:=Player.Solution+'u'; //записать ход в переменную
     end;
'.': Begin //место для ящика
      if Sklad[Player.y,Player.x]='+' then Sklad[Player.y,Player.x]:='.'
       else Sklad[Player.y,Player.x]:=' ';
      Dec(Player.y); //уменьшить вертикальную координату игрока
      Sklad[Player.y,Player.x]:='+';
      Player.Solution:=Player.Solution+'u'; //записать ход в переменную
     end;
'$': begin //ящик
      if Player.y<2 then exit;
      case Sklad[Player.y-2,Player.x] of
       ' ': begin //пусто
          Sklad[Player.y-2,Player.x]:='$';
          Sklad[Player.y-1,Player.x]:='@';
          if Sklad[Player.y,Player.x]='+' then Sklad[Player.y,Player.x]:='.'
            else Sklad[Player.y,Player.x]:=' ';
          Dec(Player.y);
          Player.Solution:=Player.Solution+'U';
            end;
       '.': begin //цель
               Sklad[Player.y-2,Player.x]:='*';
               Sklad[Player.y-1,Player.x]:='@';
               if Sklad[Player.y,Player.x]='+' then Sklad[Player.y,Player.x]:='.'
                 else Sklad[Player.y,Player.x]:=' ';
               Dec(Player.y);
               Player.Solution:=Player.Solution+'U';
            end;
      end;
     end;
'*': begin //ящик на цели
      if Player.y<2 then exit;
      case Sklad[Player.y-2,Player.x] of
       ' ': begin //пусто
          Sklad[Player.y-2,Player.x]:='$';
          Sklad[Player.y-1,Player.x]:='+';
          if Sklad[Player.y,Player.x]='+' then Sklad[Player.y,Player.x]:='.'
            else Sklad[Player.y,Player.x]:=' ';
          Dec(Player.y);
          Player.Solution:=Player.Solution+'U';
       end;
       '.': begin //цель
               Sklad[Player.y-2,Player.x]:='*';
               Sklad[Player.y-1,Player.x]:='+';
               if Sklad[Player.y,Player.x]='+' then Sklad[Player.y,Player.x]:='.'
                 else Sklad[Player.y,Player.x]:=' ';
               Dec(Player.y);
               Player.Solution:=Player.Solution+'U';
            end;
      end;
     end;
 end;  Player.animIndex:=10;
end;

procedure MoveDown; //переместиться вниз
begin
 Player.animIndex:=2;
  if Player.y=High(Sklad) then Exit;//двигаться некуда
case Sklad[Player.y+1,Player.x] of
'#': Exit;//стена
' ': Begin //пусто
      if Sklad[Player.y,Player.x]='+' then Sklad[Player.y,Player.x]:='.'
       else Sklad[Player.y,Player.x]:=' ';
      Inc(Player.y); //увеличить левую координату игрока
      Sklad[Player.y,Player.x]:='@';
      Player.Solution:=Player.Solution+'d'; //записать ход в переменную
     end;
'.': Begin //место для ящика
      if Sklad[Player.y,Player.x]='+' then Sklad[Player.y,Player.x]:='.'
       else Sklad[Player.y,Player.x]:=' ';
      Inc(Player.y); //уменьшить левую координату игрока
      Sklad[Player.y,Player.x]:='+';
      Player.Solution:=Player.Solution+'d'; //записать ход в переменную
     end;
'$': begin //ящик
      if Player.y>(High(Sklad)-1) then exit;
      case Sklad[Player.y+2,Player.x] of
       ' ': begin //пусто
          Sklad[Player.y+2,Player.x]:='$';
          Sklad[Player.y+1,Player.x]:='@';
          if Sklad[Player.y,Player.x]='+' then Sklad[Player.y,Player.x]:='.'
            else Sklad[Player.y,Player.x]:=' ';
          Inc(Player.y);
          Player.Solution:=Player.Solution+'D';
            end;
       '.': begin //цель
               Sklad[Player.y+2,Player.x]:='*';
               Sklad[Player.y+1,Player.x]:='@';
               if Sklad[Player.y,Player.x]='+' then Sklad[Player.y,Player.x]:='.'
                 else Sklad[Player.y,Player.x]:=' ';
               Inc(Player.y);
               Player.Solution:=Player.Solution+'D';
            end;
      end;
     end;
'*': begin //ящик на цели
      if Player.y>(High(Sklad)-2) then exit;
      case Sklad[Player.y+2,Player.x] of
       ' ': begin //пусто
          Sklad[Player.y+2,Player.x]:='$';
          Sklad[Player.y+1,Player.x]:='+';
          if Sklad[Player.y,Player.x]='+' then Sklad[Player.y,Player.x]:='.'
            else Sklad[Player.y,Player.x]:=' ';
          Inc(Player.y);
          Player.Solution:=Player.Solution+'D';
       end;
       '.': begin //цель
               Sklad[Player.y+2,Player.x]:='*';
               Sklad[Player.y+1,Player.x]:='+';
               if Sklad[Player.y,Player.x]='+' then Sklad[Player.y,Player.x]:='.'
                 else Sklad[Player.y,Player.x]:=' ';
               Inc(Player.y);
               Player.Solution:=Player.Solution+'D';
            end;
      end;
     end;
 end;Player.animIndex:=10;
end;

procedure uPlayerBack;
begin
 SetLength(Player.Solution,Length(Player.Solution)-1);
 Inc(Player.y);//изменить координату
 case Sklad[Player.y-1,Player.x] of//предыдущая позиция
'@': Sklad[Player.y-1,Player.x]:=' ';//пусто
'+': Sklad[Player.y-1,Player.x]:='.';//цель
 end;
 case Sklad[Player.y,Player.x] of //текущая позиция
' ': Sklad[Player.y,Player.x]:='@';//игрок
'.': Sklad[Player.y,Player.x]:='+';//игрок на цели
 end;
end;

procedure dPlayerBack;
begin
 SetLength(Player.Solution,Length(Player.Solution)-1);
 Dec(Player.y);
 case Sklad[Player.y+1,Player.x] of
 '@': Sklad[Player.y+1,Player.x]:=' ';
 '+': Sklad[Player.y+1,Player.x]:='.';
 end;
 case Sklad[Player.y,Player.x] of
 ' ': Sklad[Player.y,Player.x]:='@';
 '.': Sklad[Player.y,Player.x]:='+';
 end;
end;

procedure lPlayerBack;
begin
 SetLength(Player.Solution,Length(Player.Solution)-1);
 Inc(Player.x);
 case Sklad[Player.y,Player.x-1] of
 '@': Sklad[Player.y,Player.x-1]:=' ';
 '+': Sklad[Player.y,Player.x-1]:='.';
 end;
 case Sklad[Player.y,Player.x] of
 ' ': Sklad[Player.y,Player.x]:='@';
 '.': Sklad[Player.y,Player.x]:='+';
 end;
end;

procedure rPlayerBack;
begin
 SetLength(Player.Solution,Length(Player.Solution)-1);
 Dec(Player.x);
 case Sklad[Player.y,Player.x+1] of
 '@': Sklad[Player.y,Player.x+1]:=' ';
 '+': Sklad[Player.y,Player.x+1]:='.';
 end;
 case Sklad[Player.y,Player.x] of
 ' ': Sklad[Player.y,Player.x]:='@';
 '.': Sklad[Player.y,Player.x]:='+';
 end;
end;

procedure uBoxBack;
begin
 case Sklad[Player.y-2,Player.x] of
  '$':Sklad[Player.y-2,Player.x]:=' ';
  '*':Sklad[Player.y-2,Player.x]:='.';
 end;
 case Sklad[Player.y-1,Player.x] of
 ' ': Sklad[Player.y-1,Player.x]:='$';
 '.': Sklad[Player.y-1,Player.x]:='*';
 end;
end;

procedure dBoxBack;
begin
 case Sklad[Player.y+2,Player.x] of
 '$': Sklad[Player.y+2,Player.x]:=' ';
 '*': Sklad[Player.y+2,Player.x]:='.';
 end;
 case Sklad[Player.y+1,Player.x] of
 ' ': Sklad[Player.y+1,Player.x]:='$';
 '.': Sklad[Player.y+1,Player.x]:='*';
 end;
end;

procedure lBoxBack;
begin
 case Sklad[Player.y,Player.x-2] of
 '$': Sklad[Player.y,Player.x-2]:=' ';
 '*': Sklad[Player.y,Player.x-2]:='.';
 end;
 case Sklad[Player.y,Player.x-1] of
 ' ': Sklad[Player.y,Player.x-1]:='$';
 '.': Sklad[Player.y,Player.x-1]:='*';
 end;
end;

procedure rBoxBack;
begin
 case Sklad[Player.y,Player.x+2] of
 '$': Sklad[Player.y,Player.x+2]:=' ';
 '*': Sklad[Player.y,Player.x+2]:='.';
 end;
 case Sklad[Player.y,Player.x+1] of
 ' ': Sklad[Player.y,Player.x+1]:='$';
 '.': Sklad[Player.y,Player.x+1]:='*';
 end;
end;

procedure ChangeMatrixWidth(aNewWidth: Integer);
var i,j,d: Integer;
begin
  TraceLog(LOG_INFO,Pchar((IntToStr(High(Sklad[0])))+' width change before'));
 //Log.Info(IntToStr(High(Sklad[0])),'width change before');
 TraceLog(LOG_INFO,Pchar((IntToStr(aNewWidth))+' aNewWidth'));
 //Log.Info(IntToStr(aNewWidth),'aNewWidth');

 d:=aNewWidth-(High(Sklad[0])+1);//учитываем разницу
 if d=0 then Exit;
 TraceLog(LOG_INFO, PChar(IntToStr(d)));
 if d>0 then begin //если разница положительная, увеличиваем кол-во столбцов
  //для каждой строки в цикле
  for i:=0 to High(Sklad) do
   SetLength(Sklad[i],aNewWidth);
  //дополнительные столбцы заполняем пробелами
  for i:=0 to High(Sklad) do
   for j:=(High(Sklad[i])+1-d) to High(Sklad[i]) do Sklad[i,j]:=' ';
 end else begin //уменьшаем ширину
    //для каждой строки в цикле
    for i:=0 to High(Sklad)-1 do begin
    //Log.Info(IntToStr(High(Sklad[i])),'width change before--');
       SetLength(Sklad[i],aNewWidth);
      // Log.Info(IntToStr(High(Sklad[i])),'width change after--');
    end;
 end;
// Log.Info(IntToStr(High(Sklad[0])),'width change after');
end;

procedure ChangeMatrixHeight(aNewHeight: Integer);
var i,j,d: Integer;
begin
 //Log.Info(IntToStr(High(Sklad)),'height change before');
 d:=aNewHeight-(High(Sklad)+1);//учитываем разницу
 if d=0 then Exit;
 //Log.Info(IntToStr(d),'d');
 if d>0 then begin //добавляем строки
  SetLength(Sklad,aNewHeight);
  for i:=(High(Sklad)-d+1) to High(Sklad) do begin
   SetLength(Sklad[i],High(Sklad[0])+1);//выделяем память под новую строку
   for j:=0 to High(Sklad[0]) do Sklad[i,j]:=' ';
  end;
 end else SetLength(Sklad,aNewHeight); //иначе уменьшаем колличество строк
 //Log.Info(IntToStr(High(Sklad)),'height change after');
end;

end.

