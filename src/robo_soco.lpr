program robo_soco;

{$mode Delphi}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, CustApp, RayLib, RayMath, rayGui, GameCamera, GameLogic, rlights;

type
  { TGameState}
  TGameState = (GsMenu,GsGame, GsSetting);

  { TRayApplication }
  TRayApplication = class(TCustomApplication)
  private
    GameState : TGameState;
    PlayerRobot, Grass, DoIn, Brick, BoxOut, BoxIn, Tree1, Tree2, Mushroom, Crystal: TModel;
    modelAnimations: PModelAnimation;
    //MenuCamera: TCamera;
    Shader: TShader;
    GameCamera: rlTPCamera;
    CurrentFrame, fogDensity: single;
    animsCount, animIndex, fogDensityLoc: Integer;
  protected
    procedure DoRun; override;
    procedure LoadingModel;
    procedure UnLoadModel;
    procedure MovePlayer;
    procedure DrawScene;
    procedure DrawMap;
    procedure UndoClick;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
  end;

  const AppTitle = 'RoboSocoban';

{ TRayApplication }

constructor TRayApplication.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);

  InitWindow(800, 600, AppTitle);

  // setting game camera
  rlTPCameraInit(@GameCamera, 45, Vector3Create( 0, 0 ,0 ));
  GameCamera.ViewAngles.y := -65 * DEG2RAD;
  GameCamera.MoveSpeed := Vector3Create(0,0,0);
  GameCamera.CameraPullbackDistance := 40;

 // SetTargetFPS(60);

  GameState := gsGame;

  GuiLoadStyle(PChar(GetApplicationDirectory + 'data/gui/cyber.rgs'));
  LoadingModel;
  animsCount := 0;
  animIndex := 0;
  CurrentFrame := 0;
  modelAnimations := LoadModelAnimations(PChar(GetApplicationDirectory + 'data/models/robot.glb'), @animsCount);



  CurrLevel := 0; Nextlevel;

end;

procedure TRayApplication.DoRun;
var anim: TModelAnimation; TextS: Integer;
begin
  while (not WindowShouldClose) do // Detect window close button or ESC key
  begin
    case GameState of
    gsGame:
      begin
        // Update
        rlTPCameraUpdate(@GameCamera);
        SetShaderValue(shader, fogDensityLoc, @fogDensity, SHADER_UNIFORM_FLOAT);
                // Update the light shader with the camera view position


        SetWindowTitle(PChar(AppTitle + ' - Level '+ IntToStr(CurrLevel)));

        animIndex := Player.animIndex;
        anim := modelAnimations[animIndex];
        if CheckWin then CurrentFrame := CurrentFrame  + (anim.frameCount*GetFrameTime)
        else CurrentFrame := CurrentFrame + 0.3 + (anim.frameCount*GetFrameTime);

        if (CurrentFrame < anim.frameCount) then
        UpdateModelAnimation(PlayerRobot, anim, round(CurrentFrame));

        MovePlayer;
        SetShaderValue(shader, shader.locs[SHADER_LOC_VECTOR_VIEW], @GameCamera.ViewCamera.position.x, SHADER_UNIFORM_VEC3);
        // Draw
        BeginDrawing();
         ClearBackground(ColorCreate(169,148,126,255));

          rlTPCameraBeginMode3D(@GameCamera);
             DrawScene;
             rlTPCameraSetPosition(@GameCamera, Vector3Create(player.x*2, -0.5 ,Player.y*2));

          rlTPCameraEndMode3D();
          DrawMap;

          if not CheckWin then
          begin
            if GuiButton(RectangleCreate( GetScreenWidth - 120, 10, 100, 30 ), '#56#UNDO')>0
            then  UndoClick;

            if GuiButton(RectangleCreate( GetScreenWidth - 120, 42, 100, 30 ), '#211#RESTART') > 0 then
            begin
              Dec(CurrLevel);
              Nextlevel;
            end;
          end;

          if CheckWin then
          begin
            Player.animIndex := 0;
            UpdateModelAnimation(PlayerRobot, anim, round(CurrentFrame));
            TextS:=MeasureText(TextFormat('Level: %i complete !', CurrLevel), 40);
            DrawText(TextFormat('Level: %i complete', CurrLevel), GetScreenWidth div 2 - TextS div 2 , GetScreenHeight div 2, 40, BLUE);
            TextS:=MeasureText('Press Space to next level.', 30);
            DrawText('Press Space to next level.', GetScreenWidth div 2 - TextS div 2 ,
            GetScreenHeight div 2 + 40 , 30, BLACK);
            if IsKeyReleased(KEY_SPACE) then NextLevel;
          end;
        EndDrawing();
      end;
    end;
   end;
  // Stop program loop
  Terminate;
end;

procedure TRayApplication.LoadingModel;
var ambientLoc, i: Integer;
    locValue: array [0..3] of single;

begin
  PlayerRobot := LoadModel(PChar(GetApplicationDirectory + 'data/models/robot.glb'));
  Grass :=  LoadModel(PChar(GetApplicationDirectory +'data/models/Block_Dirt.gltf'));
  DoIn :=  LoadModel(PChar(GetApplicationDirectory + 'data/models/Block_Diamond.gltf'));
  Brick :=  LoadModel(PChar(GetApplicationDirectory + 'data/models/Cube_Crate.gltf'));
  BoxOut :=  LoadModel(PChar(GetApplicationDirectory + 'data/models/Cube_Question.gltf'));
  BoxIn :=  LoadModel(PChar(GetApplicationDirectory + 'data/models/Cube_Exclamation.gltf'));

  Tree1 := LoadModel(PChar(GetApplicationDirectory + 'data/models/DeadTree_1.gltf'));
  Tree2 := LoadModel(PChar(GetApplicationDirectory + 'data/models/DeadTree_2.gltf'));

  Mushroom := LoadModel(PChar(GetApplicationDirectory + 'data/models/Mushroom.gltf'));
  Crystal := LoadModel(PChar(GetApplicationDirectory +'data/models/Crystal_Small.gltf'));

  // Load shader and set up some uniforms
  shader := LoadShader('data/shaders/lighting.vs','data/shaders/fog.fs');
  shader.locs[SHADER_LOC_MATRIX_MODEL] := GetShaderLocation(shader, 'matModel');
  shader.locs[SHADER_LOC_VECTOR_VIEW] := GetShaderLocation(shader, 'viewPos');

  locValue[0]:=0.2;
  locValue[1]:=0.2;
  locValue[2]:=0.2;
  locValue[3]:=1.0;
  // Ambient light level

  ambientLoc := GetShaderLocation(shader, 'ambient');
  SetShaderValue(shader, ambientLoc, @locValue, SHADER_UNIFORM_VEC4);

  fogDensity := 0.025;
  fogDensityLoc := GetShaderLocation(shader, 'fogDensity');
  SetShaderValue(shader, fogDensityLoc, @fogDensity, SHADER_UNIFORM_FLOAT);

  for i := 0 to PlayerRobot.materialCount-1 do
  PlayerRobot.materials[i].shader := Shader;

  for i := 0 to Grass.materialCount-1 do
  Grass.materials[i].shader := Shader;

  for i := 0 to DoIn.materialCount-1 do
  DoIn.materials[i].shader := Shader;

  for i := 0 to Brick.materialCount-1 do
  Brick.materials[i].shader := Shader;

  for i := 0 to BoxOut.materialCount-1 do
  BoxOut.materials[i].shader := Shader;

  for i := 0 to BoxIn.materialCount-1 do
  BoxIn.materials[i].shader := Shader;

  for i := 0 to Tree1.materialCount-1 do
  Tree1.materials[i].shader := Shader;

  for i := 0 to Tree2.materialCount-1 do
  Tree2.materials[i].shader := Shader;

  for i := 0 to Mushroom.materialCount-1 do
  Mushroom.materials[i].shader := Shader;

  for i := 0 to Mushroom.materialCount-1 do
  Crystal.materials[i].shader := Shader;

  CreateLight(LIGHT_POINT, Vector3Create( 0, 20, 26 ), Vector3Zero(), WHITE, shader);
  //CreateLight(LIGHT_POINT, Vector3Create( 0, 10, 10 ), Vector3Zero(), WHITE, shader);
end;

procedure TRayApplication.UnLoadModel;
begin
  rayLib.UnLoadModel(PlayerRobot);
  rayLib.UnLoadModel(Grass);
  rayLib.UnLoadModel(DoIn);
  rayLib.UnLoadModel(Brick);
  rayLib.UnLoadModel(BoxOut);
  rayLib.UnLoadModel(BoxIn);
  rayLib.UnLoadModel(Tree1);
  rayLib.UnLoadModel(Tree2);
  rayLib.UnLoadModel(Mushroom);
  rayLib.UnLoadModel(Crystal);
end;

procedure TRayApplication.MovePlayer;
begin
  if IsKeyReleased(KEY_W) then
  begin
    PlayerRobot.transform :=  MatrixRotateXYZ(Vector3Create(0,DEG2RAD * 180,0));
    MoveUp;
    CurrentFrame :=0;
  end;
  if IsKeyReleased(KEY_S) then
  begin
    PlayerRobot.transform :=  MatrixRotateXYZ(Vector3Create(0,DEG2RAD * 0,0));
    MoveDown;
    CurrentFrame :=0;
  end;
  if IsKeyReleased(KEY_A) then
  begin
    PlayerRobot.transform :=  MatrixRotateXYZ(Vector3Create(0,DEG2RAD * -90,0));
    MoveLeft;
    CurrentFrame :=0;
  end;
  if IsKeyReleased(KEY_D) then
  begin
    PlayerRobot.transform :=  MatrixRotateXYZ(Vector3Create(0,DEG2RAD * 90,0));
    MoveRight;
    CurrentFrame :=0;
  end;
  if IsKeyReleased(KEY_SPACE) then
  begin
    TakeScreenshot(PChar('soko'+FloatToStr(GetTime)+'.png'));
  end;
end;

procedure TRayApplication.DrawScene;
var xx,yy: integer;
begin
  for xx:= 0 to High(Sklad) do
  for yy:= 0 to High(Sklad[xx]) do
  begin
    DrawModel(Grass,Vector3Create(yy*2, -2.0  ,xx*2),1,White);
    case Sklad[xx,yy] of
    '#':  DrawModel(Brick,Vector3Create(yy*2,0,xx*2),1,White);
    '.': begin
           DrawModel(DoIn,Vector3Create(yy*2, -1.9  ,xx*2),1, White);
         end;
    '@': begin
       //  DrawModel(Dirt,Vector3Create(yy*2, -1.0  ,xx*2),1,White);
       // DrawModel(PlayerModel,Vector3Create(yy*2, -0.5 ,xx*2),0.5,White);
       //   CamTaget := Vector3Create(yy*2, -0.5 ,xx*2);
         end;
    '+': begin
           DrawModel(DoIn,Vector3Create(yy*2, -1.9  ,xx*2),1, White);
           DrawModel(PlayerRobot,Vector3Create(yy*2, -1 ,xx*2),0.5,White);
         end;
    '$': DrawModel(BoxOut,Vector3Create(yy*2, 0 ,xx*2),1,White);
    '*': DrawModel(BoxIn,Vector3Create(yy*2,  0,xx*2),1,White);
    'T': DrawModel(Tree1,Vector3Create(yy*2, -1,xx*2),1,White);
    't': DrawModel(Tree2,Vector3Create(yy*2,-1,xx*2),1,White);
    'm': DrawModel(Mushroom,Vector3Create(yy*2,-1,xx*2),1,White);
    'c': DrawModel(Crystal,Vector3Create(yy*2,-1,xx*2),1,White);
    end;
  end;
  DrawModel(PlayerRobot,Vector3Create(player.x*2, -1 , Player.y*2),0.5,White);
end;

procedure TRayApplication.DrawMap;
var xx,yy, Sc, offset: integer;
begin
 Sc:= 10; OffSet:= 10;
 if not CheckWin then
 begin
 for xx:= 0 to High(Sklad) do
 for yy:= 0 to High(Sklad[xx]) do
 begin
   case Sklad[xx,yy] of
   ' ': begin
          DrawRectangle( (yy * sc)+ OffSet,  (xx * sc)+ OffSet, sc, sc, LIGHTGRAY);
          DrawRectangleLines( (yy * sc)+ OffSet,  (xx * sc)+ OffSet, sc, sc, GRAY);
        end;
   '#': begin
          DrawRectangle( (yy * sc)+ OffSet,  (xx * sc)+ OffSet, sc, sc,RED);
        end;
   '.': begin
          DrawRectangle( (yy * sc)+ OffSet ,  (xx * sc)+ OffSet, sc, sc, GRAY);
        end;
   '@': begin
          DrawRectangle( (yy * sc)+ OffSet ,  (xx * sc)+ OffSet, sc, sc,ORANGE);
        end;
   '+': begin
          DrawRectangle( (yy * sc)+ OffSet ,  (xx * sc)+ OffSet, sc, sc, ORANGE);
          DrawRectangle( (yy * sc)+ OffSet ,  (xx * sc)+ OffSet, sc, sc, GRAY);
        end;
   '$': DrawRectangle( (yy * sc)+ OffSet ,  (xx * sc)+ OffSet, sc, sc, BLUE);
   '*': DrawRectangle( (yy * sc)+ OffSet ,  (xx * sc)+ OffSet, sc, sc, GREEN);
   'T', 't','m','c' : begin
        DrawRectangle( (yy * sc)+ OffSet,  (xx * sc)+ OffSet, sc, sc, LIGHTGRAY);
        DrawRectangleLines( (yy * sc)+ OffSet,  (xx * sc)+ OffSet, sc, sc, GRAY);
       end;
   end;

 end;
 end;
end;

procedure TRayApplication.UndoClick;
var c : Char;
begin
 if Player.Solution='' then Exit;
 c:=Player.Solution[Length(Player.Solution)];
 case c of
'u':uPlayerBack;
'U':begin
     uPlayerBack;
     uBoxBack;
    end;
'd':dPlayerBack;
'D':begin
     dPlayerBack;
     dBoxBack;
    end;
'l':lPlayerBack;
'L':begin
     lPlayerBack;
     lBoxBack;
    end;
'r':rPlayerBack;
'R':begin
     rPlayerBack;
     rBoxBack;
    end;
end;
end;

destructor TRayApplication.Destroy;
begin
  // De-Initialization
  UnLoadModel;
  CloseWindow(); // Close window and OpenGL context

  // Show trace log messages (LOG_DEBUG, LOG_INFO, LOG_WARNING, LOG_ERROR...)
  TraceLog(LOG_INFO, 'your first window is close and destroy');

  inherited Destroy;
end;

var
  Application: TRayApplication;
begin
  Application:=TRayApplication.Create(nil);
  Application.Title:=AppTitle;
  Application.Run;
  Application.Free;
end.

