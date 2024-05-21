unit ScreenMenu;

{$mode ObjFPC}{$H+}

interface

uses
  RayLib, RayGui, Classes, SysUtils, ScreenManager;

type
{ TScreenMenu }
TScreenMenu = class(TGameScreen)
 private
   Owner: TRayApplication;
   PlayerRobot: TModel;
 public
   constructor Create(AOwner: TGameScreens; AData: Pointer); override;
   procedure Init; override; // Init game screen
   procedure Shutdown; override; // Shutdown the game screen
   procedure Update(MoveCount: Single); override; // Update the game screen
   procedure Render; override;  // Render the game screen
   procedure Show; override;  // Celled when the screen is showned
   procedure Hide; override; // Celled when the screen is hidden
end;

implementation

{ TScreenMenu }

constructor TScreenMenu.Create(AOwner: TGameScreens; AData: Pointer);
begin
  inherited Create(AOwner, AData);
  //PlayerRobot := AOwner.p  TRayApplication
end;

procedure TScreenMenu.Init;
begin

end;

procedure TScreenMenu.Shutdown;
begin

end;

procedure TScreenMenu.Update(MoveCount: Single);
begin

end;

procedure TScreenMenu.Render;
begin
  inherited Render;
end;

procedure TScreenMenu.Show;
begin
  inherited Show;
end;

procedure TScreenMenu.Hide;
begin
  inherited Hide;
end;

end.

