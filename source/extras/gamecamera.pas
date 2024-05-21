unit GameCamera;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, RayLib, RayMath, RlGl, Math;

type
  PrlTpCameraControls = ^rlTpCameraControls;
  rlTpCameraControls = Integer;
  const
    MOVE_FRONT = rlTpCameraControls(0);
    MOVE_BACK = rlTpCameraControls(1);
    MOVE_RIGHT = rlTpCameraControls(2);
    MOVE_LEFT = rlTpCameraControls(3);
    MOVE_UP = rlTpCameraControls(4);
    MOVE_DOWN = rlTpCameraControls(5);
    TURN_LEFT = rlTpCameraControls(6);
    TURN_RIGHT = rlTpCameraControls(7);
    TURN_UP = rlTpCameraControls(8);
    TURN_DOWN = rlTpCameraControls(9);
    SPRINT = rlTpCameraControls(10);
    LAST_CONTROL = rlTpCameraControls(11);


  type
    PrlTPCamera = ^rlTPCamera;
    rlTPCamera = record
    // keys used to control the camera
    ControlsKeys: array [0..LAST_CONTROL] of Integer;
    // the speed in units/second to move, X = sidestep Y = jump/fall Z = forward
    MoveSpeed: TVector3;
    // the speed for turning when using keys to look degrees/second
    TurnSpeed: TVector2;
    // use the mouse for looking?
    UseMouse: Boolean;
    UseMouseButton: Integer;
    // how many pixels equate out to an angle move, larger numbers mean slower, more accurate mouse
    MouseSensitivity: Single;
    // how far down can the camera look
    MinimumViewY: Single;
    // how far up can the camera look
    MaximumViewY: Single;
    // the position of the base of the camera (on the floor)
    // note that this will not be the view position because it is offset by the eye height.
    // this value is also not changed by the view bobble
    CameraPosition: TVector3;
    // how far from the target position to the camera's view point (the zoom)
    CameraPullbackDistance: Single;
    // the Raylib camera to pass to raylib view functions.
    ViewCamera: TCamera;
    // the vector in the ground plane that the camera is facing
    ViewForward: TVector3;
    // the field of view in X and Y
    FOV: TVector2;
    // state for view angles
    ViewAngles: TVector2;
    // state for window focus
    Focused: Boolean;
    //clipping planes
    // note must use BeginModeFP3D and EndModeFP3D instead of BeginMode3D/EndMode3D for clipping planes to work
    NearPlane: Double; FarPlane: Double;
  end;

  // called to initialize a camera to default values
  procedure rlTPCameraInit(camera: PrlTPCamera; fovY: Single;  position: TVector3);
  // turn the use of mouselook on/off, also updates the cursor visibility and what button to use, set button to -1 to disable mouse
  procedure rlTPCameraUseMouse(camera: PrlTPCamera; useMouse: Boolean; button: Integer);
  // Get the camera's position in world (or game) space
  function rlTPCameraGetPosition(camera: PrlTPCamera): TVector3;
  // Set the camera's position in world (or game) space
  procedure rlTPCameraSetPosition(camera: PrlTPCamera; position: TVector3);
  // returns the ray from the camera through the center of the view
  function rlTPCameraGetViewRay(camera: PrlTPCamera): TRay;
  // update the camera for the current frame
  procedure rlTPCameraUpdate(camera: PrlTPCamera);
  // start drawing using the camera, with near/far plane support
  procedure rlTPCameraBeginMode3D(camera: PrlTPCamera);
  // end drawing with the camera
  procedure rlTPCameraEndMode3D();


implementation

procedure ResizeTPOrbitCameraView(camera: PrlTPCamera);
var width, height: Single;
begin
  if camera = nil then exit;
  width := GetScreenWidth();
  height := GetScreenHeight();
  camera^.FOV.y := camera^.ViewCamera.fovy;
  if (height >= 0) then
  camera^.FOV.x := camera^.FOV.y * (width / height);
end;

procedure rlTPCameraInit(camera: PrlTPCamera; fovY: Single; position: TVector3);
begin
  if camera = nil then exit;
  camera^.ControlsKeys[0] := KEY_W;;
  camera^.ControlsKeys[1] := KEY_S;
  camera^.ControlsKeys[2] := KEY_D;
  camera^.ControlsKeys[3] := KEY_A;
  camera^.ControlsKeys[4] := KEY_E;
  camera^.ControlsKeys[5] := KEY_Q;
//  camera^.ControlsKeys[6] := KEY_LEFT;
//  camera^.ControlsKeys[7] := KEY_RIGHT;
  camera^.ControlsKeys[8] := KEY_UP;
  camera^.ControlsKeys[9] := KEY_DOWN;
  camera^.ControlsKeys[10] := KEY_LEFT_SHIFT;

  camera^.MoveSpeed := Vector3Create( 3,3,3 );
  camera^.TurnSpeed := Vector2Create( 90,90 );

  camera^.MouseSensitivity := 600;

  camera^.MinimumViewY := -89.0;
  camera^.MaximumViewY := 0.0;

  camera^.Focused := IsWindowFocused();

  camera^.CameraPullbackDistance := 5;

  camera^.ViewAngles := Vector2Create( 0,0 );

  camera^.CameraPosition := position;
  camera^.FOV.y := fovY;

  camera^.ViewCamera.target := position;
  camera^.ViewCamera.position := Vector3Add(camera^.ViewCamera.target, Vector3Create ( 0, 0, camera^.CameraPullbackDistance ));
  camera^.ViewCamera.up := Vector3Create( 0.0, 2.0, 0.0 );
  camera^.ViewCamera.fovy := fovY;
  camera^.ViewCamera.projection := CAMERA_PERSPECTIVE;

  camera^.NearPlane := 0.01;
  camera^.FarPlane := 1000.0;

  ResizeTPOrbitCameraView(camera);
  rlTPCameraUseMouse(camera, true, 1);
end;

procedure rlTPCameraUseMouse(camera: PrlTPCamera; useMouse: Boolean; button: Integer);
var showCursor: Boolean;

begin
  if camera = nil then exit;
  camera^.UseMouse := useMouse;

  showCursor := (not useMouse) or (button >= 0);

  if (not showCursor) And (IsWindowFocused) then
      DisableCursor()
  else if (showCursor) and (IsWindowFocused) then
      EnableCursor();
end;

function rlTPCameraGetPosition(camera: PrlTPCamera): TVector3;
begin
  result := camera^.CameraPosition;
end;

procedure rlTPCameraSetPosition(camera: PrlTPCamera; position: TVector3);
begin
  camera^.CameraPosition := position;
end;

function rlTPCameraGetViewRay(camera: PrlTPCamera): TRay;
begin
  result.position  := camera^.CameraPosition;
  result.direction := Vector3Subtract(camera^.ViewCamera.target, camera^.ViewCamera.position);
end;

function GetSpeedForAxis(camera: PrlTPCamera; axis: rlTPCameraControls; speed: Single): Single;
var key: Integer;
    factor: Single;
begin
  result :=  0.0;
  if camera = nil then result := 0;
  key := camera^.ControlsKeys[axis];
  if key = -1 then result := 0;
  factor := 1.0;
  if IsKeyDown(camera^.ControlsKeys[SPRINT]) then factor := 2;
  if IsKeyDown(camera^.ControlsKeys[axis]) then result := speed * GetFrameTime() * factor;
end;

procedure rlTPCameraUpdate(camera: PrlTPCamera);
var showCursor, useMouse: Boolean;
    mousePositionDelta: TVector2;
    mouseWheelMove, turnRotation, tiltRotation: Single;
    direction: array[0..MOVE_DOWN] of Single;
    moveVec, camPos: TVector3;
    tiltMat, rotMat, mat: TMatrix;
begin

  if camera = nil then Exit;

  if IsWindowResized() then ResizeTPOrbitCameraView(camera);

  showCursor := (not Camera^.UseMouse) or (camera^.UseMouseButton >=0);

  if IsWindowFocused() <> (camera^.Focused and camera^.UseMouse) then
  begin
    camera^.Focused := IsWindowFocused;
    if camera^.Focused then
    DisableCursor
    else
    EnableCursor;
  end;

  // Mouse movement detection
  mousePositionDelta := GetMouseDelta();
  mouseWheelMove := GetMouseWheelMove();

  // Keys input detection
  direction[MOVE_FRONT] := -GetSpeedForAxis(camera,MOVE_FRONT,camera^.MoveSpeed.z);
  direction[MOVE_BACK] := -GetSpeedForAxis(camera,MOVE_BACK,camera^.MoveSpeed.z);
  direction[MOVE_RIGHT] := GetSpeedForAxis(camera,MOVE_RIGHT,camera^.MoveSpeed.x);
  direction[MOVE_LEFT] := GetSpeedForAxis(camera,MOVE_LEFT,camera^.MoveSpeed.x);
  direction[MOVE_UP] := GetSpeedForAxis(camera,MOVE_UP,camera^.MoveSpeed.y);
  direction[MOVE_DOWN] := GetSpeedForAxis(camera,MOVE_DOWN,camera^.MoveSpeed.y);

  useMouse := camera^.UseMouse and ((camera^.UseMouseButton <0) or IsMouseButtonDown(camera^.UseMouseButton));

  turnRotation := GetSpeedForAxis(camera, TURN_RIGHT, camera^.TurnSpeed.x) - GetSpeedForAxis(camera, TURN_LEFT, camera^.TurnSpeed.x);
  tiltRotation := GetSpeedForAxis(camera, TURN_UP, camera^.TurnSpeed.y) - GetSpeedForAxis(camera, TURN_DOWN, camera^.TurnSpeed.y);

  if turnRotation <> 0 then camera^.ViewAngles.x -= turnRotation * DEG2RAD;

  //else if useMouse and camera^.Focused then
  //camera^.ViewAngles.x -= (mousePositionDelta.x / camera^.MouseSensitivity);

  if tiltRotation <> 0 then
   camera^.ViewAngles.y += tiltRotation * DEG2RAD;
  {
  else if useMouse and camera^.Focused then
          camera^.ViewAngles.y += (mousePositionDelta.y / -camera^.MouseSensitivity);
  }
      // Angle clamp
      if (camera^.ViewAngles.y < camera^.MinimumViewY * DEG2RAD) then
          camera^.ViewAngles.y := camera^.MinimumViewY * DEG2RAD
      else if camera^.ViewAngles.y > camera^.MaximumViewY * DEG2RAD then
          camera^.ViewAngles.y := camera^.MaximumViewY * DEG2RAD;

      //movement in plane rotation space
      moveVec := Vector3Create( 0,0,0 );
      moveVec.z := direction[MOVE_FRONT] - direction[MOVE_BACK];
      moveVec.x := direction[MOVE_RIGHT] - direction[MOVE_LEFT];

      // update zoom
      camera^.CameraPullbackDistance += GetMouseWheelMove();
      if (camera^.CameraPullbackDistance < 25) then
          camera^.CameraPullbackDistance := 25;
           if (camera^.CameraPullbackDistance > 45) then
          camera^.CameraPullbackDistance := 45;
      // vector we are going to transform to get the camera offset from the target point
     camPos := Vector3Create( 0, 0, camera^.CameraPullbackDistance );

     tiltMat := MatrixRotateX(camera^.ViewAngles.y); // a matrix for the tilt rotation
     rotMat := MatrixRotateY(camera^.ViewAngles.x); // a matrix for the plane rotation
     mat := MatrixMultiply(tiltMat, rotMat); // the combined transformation matrix for the camera position

     camPos := Vector3Transform(camPos, mat); // transform the camera position into a vector in world space
     moveVec := Vector3Transform(moveVec, rotMat); // transform the movement vector into world space, but ignore the tilt so it is in plane
     camera^.CameraPosition := Vector3Add(camera^.CameraPosition, moveVec); // move the target to the moved position
      // validate cam pos here
     // set the view camera
      camera^.ViewCamera.target := camera^.CameraPosition;
      camera^.ViewCamera.position := Vector3Add(camera^.CameraPosition, camPos); // offset the camera position by the vector from the target position
end;

procedure SetupCamera(camera: PrlTPCamera; aspect: Single);
var top, right: Double;
    matView: TMatrix;
begin
  rlDrawRenderBatchActive();			// Draw Buffers (Only OpenGL 3+ and ES2)
  rlMatrixMode(RL_PROJECTION);        // Switch to projection matrix
  rlPushMatrix();                     // Save previous matrix, which contains the settings for the 2d ortho projection
  rlLoadIdentity();                   // Reset current matrix (projection)

  if (camera^.ViewCamera.projection = CAMERA_PERSPECTIVE) then
  begin
    // Setup perspective projection
    top := RL_CULL_DISTANCE_NEAR * tan(camera^.ViewCamera.fovy * 0.5 * DEG2RAD);
    right := top * aspect;
    rlFrustum(-right, right, -top, top, camera^.NearPlane, camera^.FarPlane);
   end
    else if (camera^.ViewCamera.projection = CAMERA_ORTHOGRAPHIC) then
    begin
      // Setup orthographic projection
      top := camera^.ViewCamera.fovy / 2.0;
      right := top * aspect;
      rlOrtho(-right, right, -top, top, camera^.NearPlane, camera^.FarPlane);
    end;

    // NOTE: zNear and zFar values are important when computing depth buffer values

    rlMatrixMode(RL_MODELVIEW);         // Switch back to modelview matrix
    rlLoadIdentity();                   // Reset current matrix (modelview)

    // Setup Camera view
    matView := MatrixLookAt(camera^.ViewCamera.position, camera^.ViewCamera.target, camera^.ViewCamera.up);
    rlMultMatrixf(MatrixToFloatV(matView).v);      // Multiply modelview matrix by view matrix (camera)

    rlEnableDepthTest();                // Enable DEPTH_TEST for 3D
end;


procedure rlTPCameraBeginMode3D(camera: PrlTPCamera);
var aspect: Single;
begin
  if camera = nil then exit;
  aspect := GetScreenWidth() / GetScreenHeight();
  SetupCamera(camera, aspect);
end;

procedure rlTPCameraEndMode3D();
begin
  EndMode3D();
end;







end.

