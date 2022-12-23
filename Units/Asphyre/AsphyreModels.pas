unit AsphyreModels;
//---------------------------------------------------------------------------
// The contents of this file are subject to the Mozilla Public License
// Version 1.1 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://www.mozilla.org/MPL/
//
// Software distributed under the License is distributed on an "AS IS"
// basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
// License for the specific language governing rights and limitations
// under the License.
//---------------------------------------------------------------------------
interface

//---------------------------------------------------------------------------
uses
 Types, Classes, SysUtils, Direct3D9, DXBase, AsphyreDef, AsphyreMath,
 AsphyreMatrix, DXTextures, DXMeshes, AsphyreMeshes, AsphyreTextures,
 AsphyreMaterials, AsphyreCameras, AsphyreDevices, AsphyreDb;

//---------------------------------------------------------------------------
type
 TAsphyreModels = class;
 TAsphyreModel  = class;

//---------------------------------------------------------------------------
 TModelCulling = (mcNone, mcCW, mcCCW);

//---------------------------------------------------------------------------
 TEnvMappingType = (emNone, emReflection, emSpherical, emPosition);

//---------------------------------------------------------------------------
 TModelTexture = record
  Index     : Integer;
  EnvMapping: TEnvMappingType;
 end;

//---------------------------------------------------------------------------
 TModelCreateEvent = procedure(Sender: TObject; Tag: Integer;
  Model: TAsphyreModel) of object;

//---------------------------------------------------------------------------
 TModelTextures = class
 private
  Data: array of TModelTexture;

  function GetCount(): Integer;
  function GetItem(Num: Integer): TModelTexture;
  procedure SetItem(Num: Integer; const Value: TModelTexture);
  function GetNeedEnvMap(): Boolean;
 public
  property Count: Integer read GetCount;
  property Items[Num: Integer]: TModelTexture read GetItem write SetItem; default;
  property NeedEnvMap: Boolean read GetNeedEnvMap;

  function Include(Index: Integer; EnvMapping: TEnvMappingType = emNone): Integer;
  procedure Remove(Num: Integer);
  procedure RemoveAll();

  constructor Create();
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
 TAsphyreModel = class
 private
  FOwner : TAsphyreModels;
  FIndex : Integer;
  FLoaded: Boolean;
  FDXMesh: TDXMesh;
  FName  : string;

  FMaterial : Integer;
  FTexturing: TModelTextures;
  FCulling  : TModelCulling;
  FLighting : Boolean;
  FScale    : Real;

  procedure DisableTextureStage(Stage: Cardinal);
  procedure StageEnvMapping(Stage: Cardinal; EnvMapping: TEnvMappingType;
   Camera: TAsphyreCamera; const WorldMtx: TMatrix4);
  procedure StageMultiOp(Stage: Cardinal);
  procedure VerifyDeviceCapabilities();
  procedure UpdateMaterial();
  procedure UpdateTexturing(Camera: TAsphyreCamera; const WorldMtx: TMatrix4);
  procedure UpdateStates();
  procedure CreateDXMesh();
 public
  property Owner: TAsphyreModels read FOwner;
  property Index: Integer read FIndex;
  property Name : string read FName write FName;

  property Loaded: Boolean read FLoaded;
  property DXMesh: TDXMesh read FDXMesh;

  // material properties
  property Material : Integer read FMaterial write FMaterial;
  // mono/multi-texturing
  property Texturing: TModelTextures read FTexturing;

  // triangle culling
  property Culling  : TModelCulling read FCulling write FCulling;

  property Lighting : Boolean read FLighting write FLighting;

  // scale factor is only applied when the mesh is loaded
  property Scale    : Real read FScale write FScale;

  function LoadFromFile(const Filename: string): Boolean;
  function LoadFromASDb(const Key: string; ASDb: TASDb): Boolean;
  function LoadFromMesh(Source: TAsphyreMesh): Boolean;

  procedure Release();

  function Draw(const WorldMtx: TMatrix4; Camera: TAsphyreCamera): Boolean; overload;
  function Draw(Matrix: TAsphyreMatrix; Camera: TAsphyreCamera): Boolean; overload;

  constructor Create(AOwner: TAsphyreModels);
  destructor Destroy(); override;
 end;

//---------------------------------------------------------------------------
 TAsphyreModels = class(TAsphyreDeviceSubscriber)
 private
  Data: array of TAsphyreModel;

  FMaterials: TAsphyreMaterials;
  FTextures : TAsphyreTextures;

  FCamera   : TAsphyreCamera;
  FOnModelCreate: TModelCreateEvent;

  procedure SetTransforms(const ViewMtx, ProjMtx: TMatrix4);
  procedure SetCamera(const Value: TAsphyreCamera);
  function GetCount(): Integer;
  function GetItem(Num: Integer): TAsphyreModel;
  function GetModel(Name: string): TAsphyreModel;
 protected
  procedure Notification(AComponent: TComponent;
   Operation: TOperation); override;
  function HandleNotice(Msg: Cardinal): Boolean; override;
 public
  // # of models available
  property Count: Integer read GetCount;

  // individual model, Num is [0..Count - 1]
  property Items[Num: Integer]: TAsphyreModel read GetItem; default;

  property Model[Name: string]: TAsphyreModel read GetModel;

  // pre-cached camera (saves View / Projection matrix updates)
  property Camera: TAsphyreCamera read FCamera write SetCamera;

  //---------------------------------------------------------------------------
  // Adds an uninitialized model to the list.
  //---------------------------------------------------------------------------
  function Add(): TAsphyreModel;

  //---------------------------------------------------------------------------
  // Searches through the list to find the index of the given model.
  // If no model is found, returns -1
  //---------------------------------------------------------------------------
  function Find(Model: TAsphyreModel): Integer;

  //---------------------------------------------------------------------------
  // Removes model at the specified index from the list.
  //---------------------------------------------------------------------------
  procedure Remove(Index: Integer);

  //---------------------------------------------------------------------------
  // Removes all previously loaded models.
  //---------------------------------------------------------------------------
  procedure RemoveAll();

  //---------------------------------------------------------------------------
  // Adds a new model and loads its mesh data from external file.
  //---------------------------------------------------------------------------
  function AddFromFile(const Filename: string; Tag: Integer): Boolean;

  //---------------------------------------------------------------------------
  // Adds a new model and loads its mesh data from external file.
  //---------------------------------------------------------------------------
  function AddFromASDb(const Key: string; ASDb: TASDb; Tag: Integer): Boolean;

  constructor Create(AOwner: TComponent); override;
  destructor Destroy(); override;
 published
  property Materials: TAsphyreMaterials read FMaterials write FMaterials;
  property Textures : TAsphyreTextures read FTextures write FTextures;
  property OnModelCreate: TModelCreateEvent read FOnModelCreate write FOnModelCreate;
 end;

//---------------------------------------------------------------------------
function DXTextureTransformN(Num: Integer): TD3DTransformStateType;

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
function DXTextureTransformN(Num: Integer): TD3DTransformStateType;
begin
 case Num of
  1: Result:= D3DTS_TEXTURE1;
  2: Result:= D3DTS_TEXTURE2;
  3: Result:= D3DTS_TEXTURE3;
  4: Result:= D3DTS_TEXTURE4;
  5: Result:= D3DTS_TEXTURE5;
  6: Result:= D3DTS_TEXTURE6;
  7: Result:= D3DTS_TEXTURE7;
  else Result:= D3DTS_TEXTURE0;
 end;
end;

//---------------------------------------------------------------------------
constructor TModelTextures.Create();
begin
 inherited;

 SetLength(Data, 0);
end;

//---------------------------------------------------------------------------
destructor TModelTextures.Destroy();
begin
 SetLength(Data, 0);

 inherited;
end;

//---------------------------------------------------------------------------
function TModelTextures.GetCount(): Integer;
begin
 Result:= Length(Data);
end;

//---------------------------------------------------------------------------
function TModelTextures.GetItem(Num: Integer): TModelTexture;
begin
 if (Num < 0)or(Num >= Length(Data)) then
  begin
   Result.Index  := -1;
   Result.EnvMapping:= emNone;
   Exit;
  end else Result:= Data[Num];
end;

//---------------------------------------------------------------------------
procedure TModelTextures.SetItem(Num: Integer; const Value: TModelTexture);
begin
 if (Num >= 0)and(Num < Length(Data)) then Data[Num]:= Value;
end;

//---------------------------------------------------------------------------
function TModelTextures.Include(Index: Integer;
 EnvMapping: TEnvMappingType): Integer;
var
 Num: Integer;
begin
 Num:= Length(Data);
 SetLength(Data, Length(Data) + 1);

 Data[Num].Index     := Index;
 Data[Num].EnvMapping:= EnvMapping;

 Result:= Num;
end;

//---------------------------------------------------------------------------
procedure TModelTextures.Remove(Num: Integer);
var
 i: Integer;
begin
 if (Num < 0)or(Num >= Length(Data)) then Exit;

 for i:= Num to Length(Data) - 2 do
  Data[i]:= Data[i + 1];

 SetLength(Data, Length(Data) - 1);
end;

//---------------------------------------------------------------------------
procedure TModelTextures.RemoveAll();
begin
 SetLength(Data, 0);
end;

//---------------------------------------------------------------------------
function TModelTextures.GetNeedEnvMap(): Boolean;
var
 i: Integer;
begin
 Result:= False;

 for i:= 0 to Length(Data) - 1 do
  if (Data[i].EnvMapping <> emNone) then
   begin
    Result:= True;
    Break;
   end;
end;

//---------------------------------------------------------------------------
constructor TAsphyreModel.Create(AOwner: TAsphyreModels);
begin
 inherited Create();

 FOwner:= AOwner;
 FIndex:= -1;
 FName := '[unnamed]';

 FLoaded  := False;
 FMaterial:= -1;
 FCulling := mcCCW;
 FLighting:= True;
 FScale   := 1.0;

 FTexturing:= TModelTextures.Create();
end;

//---------------------------------------------------------------------------
destructor TAsphyreModel.Destroy();
begin
 Release();
 FTexturing.Free();

 inherited;
end;

//---------------------------------------------------------------------------
procedure TAsphyreModel.Release();
begin
 if (FDXMesh <> nil) then
  begin
   FDXMesh.Free();
   FDXMesh:= nil;
  end;

 FLoaded:= False;
end;

//---------------------------------------------------------------------------
procedure TAsphyreModel.VerifyDeviceCapabilities();
var
 MaxStages: Cardinal;
begin
 MaxStages:= DeviceCaps.MaxTextureBlendStages;
 if (MaxStages > DeviceCaps.MaxSimultaneousTextures) then
  MaxStages:= DeviceCaps.MaxSimultaneousTextures;
 if (Integer(MaxStages) > 8) then MaxStages:= 8;

 // remove unsupported texture stages
 while (FTexturing.Count > Integer(MaxStages)) do
  FTexturing.Remove(FTexturing.Count - 1);
end;

//---------------------------------------------------------------------------
procedure TAsphyreModel.CreateDXMesh();
begin
 if (FDXMesh <> nil) then FDXMesh.Free();

 if (FTexturing.NeedEnvMap) then
  begin
   FDXMesh:= TDXEnvironmentMesh.Create(FTexturing.Count);
  end else
  begin
   FDXMesh:= TDXTexturedMesh.Create(FTexturing.Count);
  end;
end;

//---------------------------------------------------------------------------
function TAsphyreModel.LoadFromMesh(Source: TAsphyreMesh): Boolean;
begin
 if (FLoaded) then
  begin
   Result:= False;
   Exit;
  end;

 VerifyDeviceCapabilities();

 CreateDXMesh();
 Result:= FDXMesh.LoadFromMesh(Source, True);
 if (not Result) then
  begin
   FDXMesh.Free();
   Exit;
  end;

 FLoaded:= True;
end;

//---------------------------------------------------------------------------
function TAsphyreModel.LoadFromFile(const Filename: string): Boolean;
var
 Mesh: TAsphyreMesh;
begin
 // (1) Initial conditions.
 if (FLoaded) then
  begin
   Result:= False;
   Exit;
  end;

 // (2) Create Asphyre Mesh.
 Mesh:= TAsphyreMesh.Create();

 // (3) Load mesh data from file.
 Result:= Mesh.LoadFromFile(Filename);
 if (not Result) then
  begin
   Mesh.Free();
   Exit;
  end;

 // -> rescale if necessary
 if (FScale <> 1.0) then Mesh.Rescale(FScale);

 // (4) Verify device capabilities.
 VerifyDeviceCapabilities();

 // (5) Create DirectX-compatible mesh.
 CreateDXMesh();
 Result:= FDXMesh.LoadFromMesh(Mesh, True);
 if (not Result) then
  begin
   Mesh.Free();
   FDXMesh.Free();
   Exit;
  end;

 // (6) Release Asphyre mesh & update status.
 Mesh.Free();
 FLoaded:= True;
end;

//---------------------------------------------------------------------------
function TAsphyreModel.LoadFromASDb(const Key: string; ASDb: TASDb): Boolean;
var
 Stream: TMemoryStream;
 Mesh  : TAsphyreMesh;
begin
 // (1) Make sure ASDb is up-to-date.
 Result:= ASDb.UpdateOnce();
 if (not Result) then Exit;

 // (2) Create a memory stream and load it from ASDb.
 Stream:= TMemoryStream.Create();
 Result:= ASDb.ReadStream(Key, Stream);
 if (not Result) then
  begin
   Stream.Free();
   Exit;
  end;

 // (3) Create a new mesh and load it from the stream.
 Stream.Seek(0, soFromBeginning);
 Mesh:= TAsphyreMesh.Create();
 Result:= Mesh.LoadFromStream(Stream);
 if (not Result) then
  begin
   Mesh.Free();
   Stream.Free();
   Exit;
  end;

 // (4) Release the stream.
 Stream.Free();

 // -> rescale if necessary
 if (FScale <> 1.0) then Mesh.Rescale(FScale);

 // (5) Verify device capabilities.
 VerifyDeviceCapabilities();

 // (6) Create a DirectX-compatible mesh.
 CreateDXMesh();
 Result:= FDXMesh.LoadFromMesh(Mesh, True);
 if (not Result) then
  begin
   Mesh.Free();
   FDXMesh.Free();
   Exit;
  end;

 // (7) Release the mesh and update status.
 Mesh.Free();
 FLoaded:= True;
end;

//---------------------------------------------------------------------------
procedure TAsphyreModel.UpdateMaterial();
var
 Material: TAsphyreMaterial;
begin
 if (FMaterial <> -1)and(Assigned(Owner))and(Assigned(Owner.Materials)) then
  begin
   Material:= Owner.Materials[FMaterial];
   if (Material <> nil) then Material.Activate();
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreModel.DisableTextureStage(Stage: Cardinal);
begin
 with Direct3DDevice do
  begin
   SetTextureStageState(Stage, D3DTSS_COLOROP, D3DTOP_DISABLE);
   SetTextureStageState(Stage, D3DTSS_ALPHAOP, D3DTOP_DISABLE);
   SetTexture(Stage, nil);
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreModel.StageEnvMapping(Stage: Cardinal;
 EnvMapping: TEnvMappingType; Camera: TAsphyreCamera; const WorldMtx: TMatrix4);
begin
 Direct3DDevice.SetTextureStageState(Stage, D3DTSS_TEXTURETRANSFORMFLAGS,
  D3DTTFF_DISABLE);

 case EnvMapping of
  emNone:
   begin // no environment mapping
    Direct3DDevice.SetTextureStageState(Stage, D3DTSS_TEXCOORDINDEX, Stage);
   end;
  emReflection:
   begin // reflection mapping
    Direct3DDevice.SetTextureStageState(Stage, D3DTSS_TEXCOORDINDEX,
     D3DTSS_TCI_CAMERASPACEREFLECTIONVECTOR or Stage);
   end;
  emSpherical: // spherical mapping
   begin
    Direct3DDevice.SetTextureStageState(Index, D3DTSS_TEXCOORDINDEX,
     D3DTSS_TCI_CAMERASPACENORMAL or Stage);
   end;
  emPosition: // positional mapping
   begin
    Direct3DDevice.SetTextureStageState(Index, D3DTSS_TEXCOORDINDEX,
     D3DTSS_TCI_CAMERASPACEPOSITION or Stage);
   end;
 end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreModel.StageMultiOp(Stage: Cardinal);
begin
 with Direct3DDevice do
  begin
   SetTextureStageState(Stage, D3DTSS_COLOROP, D3DTOP_MODULATE);
   SetTextureStageState(Stage, D3DTSS_ALPHAOP, D3DTOP_MODULATE);

   if (Stage = 0) then
    begin
     SetTextureStageState(Stage, D3DTSS_COLORARG1, D3DTA_TEXTURE);
     SetTextureStageState(Stage, D3DTSS_COLORARG2, D3DTA_DIFFUSE);
     SetTextureStageState(Stage, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
     SetTextureStageState(Stage, D3DTSS_ALPHAARG2, D3DTA_DIFFUSE);
    end else
    begin
     SetTextureStageState(Stage, D3DTSS_COLORARG1, D3DTA_TEXTURE);
     SetTextureStageState(Stage, D3DTSS_COLORARG2, D3DTA_CURRENT);
     SetTextureStageState(Stage, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
     SetTextureStageState(Stage, D3DTSS_ALPHAARG2, D3DTA_CURRENT);
    end; // if (Stage = 0)
  end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreModel.UpdateTexturing(Camera: TAsphyreCamera;
 const WorldMtx: TMatrix4);
var
 Texture: TDXBaseTexture;
 Stage  : Integer;
begin
 if (Direct3DDevice = nil) then Exit;

 // if no texturing is available, disable texture
 if (not Assigned(FOwner))or(not Assigned(FOwner.Textures)) then
  begin
   for Stage:= 0 to 7 do
    DisableTextureStage(Stage);

   Exit;
  end;

 // select the specified textures
 for Stage:= 0 to 7 do
  if (Stage < FTexturing.Count) then
   begin // apply multi-texturing
    Texture:= FOwner.Textures[FTexturing[Stage].Index];
    if (Texture <> nil) then
     begin
      Texture.Activate(Stage, 0);
      StageEnvMapping(Stage, FTexturing[Stage].EnvMapping, Camera, WorldMtx);
      StageMultiOp(Stage);
     end else DisableTextureStage(Stage);
   end else DisableTextureStage(Stage);
end;

//---------------------------------------------------------------------------
procedure TAsphyreModel.UpdateStates();
var
 Aux: Cardinal;
begin
 if (Direct3DDevice = nil) then Exit;

 with Direct3DDevice do
  begin
   // enable depth-testing
   GetRenderState(D3DRS_ZENABLE, Aux);
   if (Aux <> D3DZB_TRUE) then SetRenderState(D3DRS_ZENABLE, D3DZB_TRUE);
  end;

 // determine the type of culling
 case FCulling of
  mcCW : Aux:= D3DCULL_CW;
  mcCCW: Aux:= D3DCULL_CCW;
  else Aux:= D3DCULL_NONE;
 end;

 // triangle culling
 Direct3DDevice.SetRenderState(D3DRS_CULLMODE, Aux);

 // lighting
 Direct3DDevice.SetRenderState(D3DRS_LIGHTING, Cardinal(FLighting));


 // use normal normalization, if environment mapping is used anywhere
 Direct3DDevice.SetRenderState(D3DRS_NORMALIZENORMALS, Cardinal(FTexturing.NeedEnvMap));
end;

//---------------------------------------------------------------------------
function TAsphyreModel.Draw(const WorldMtx: TMatrix4;
 Camera: TAsphyreCamera): Boolean;
begin
 // (1) Verify conditions.
 if (not FLoaded) then
  begin
   Result:= False;
   Exit;
  end;

 // (2) Material & texturing.
 UpdateMaterial();
 UpdateTexturing(Camera, WorldMtx);
 UpdateStates();

 // (3) Set camera property.
 if (FOwner <> nil) then FOwner.Camera:= Camera;

 // (4) Render the mesh.
 Result:= FDXMesh.Draw(WorldMtx);
end;

//---------------------------------------------------------------------------
function TAsphyreModel.Draw(Matrix: TAsphyreMatrix;
 Camera: TAsphyreCamera): Boolean;
begin
 Result:= Draw(Matrix.RawMtx, Camera);
end;

//---------------------------------------------------------------------------
constructor TAsphyreModels.Create(AOwner: TComponent);
begin
 inherited;

 FMaterials:= TAsphyreMaterials(FindHelper(TAsphyreMaterials));
 FTextures := TAsphyreTextures(FindHelper(TAsphyreTextures));
end;

//---------------------------------------------------------------------------
destructor TAsphyreModels.Destroy();
begin
 RemoveAll();

 inherited;
end;

//---------------------------------------------------------------------------
procedure TAsphyreModels.Notification(AComponent: TComponent; Operation: TOperation);
begin
 inherited;

 case Operation of
  opInsert:
   begin
    if (AComponent is TAsphyreMaterials)and(not Assigned(FMaterials)) then
     FMaterials:= TAsphyreMaterials(AComponent);

    if (AComponent is TAsphyreTextures)and(not Assigned(FTextures)) then
     FTextures:= TAsphyreTextures(AComponent);
   end;

  opRemove:
   begin
    if (AComponent = FMaterials) then FMaterials:= nil;
    if (AComponent = FTextures) then FTextures:= nil;
   end;
 end;
end;

//---------------------------------------------------------------------------
procedure TAsphyreModels.SetCamera(const Value: TAsphyreCamera);
begin
 if (FCamera <> Value)and(Value <> nil) then
  SetTransforms(Value.ViewMtx, Value.ProjMtx);

 FCamera:= Value;
end;

//---------------------------------------------------------------------------
procedure TAsphyreModels.SetTransforms(const ViewMtx, ProjMtx: TMatrix4);
begin
 if (Direct3DDevice <> nil) then
  begin
   Direct3DDevice.SetTransform(D3DTS_VIEW, D3DMatrix(ViewMtx));
   Direct3DDevice.SetTransform(D3DTS_PROJECTION, D3DMatrix(ProjMtx));
  end;
end;

//---------------------------------------------------------------------------
function TAsphyreModels.GetCount(): Integer;
begin
 Result:= Length(Data);
end;

//---------------------------------------------------------------------------
function TAsphyreModels.GetItem(Num: Integer): TAsphyreModel;
begin
 if (Num >= 0)and(Num < Length(Data)) then Result:= Data[Num]
  else Result:= nil;
end;

//---------------------------------------------------------------------------
function TAsphyreModels.GetModel(Name: string): TAsphyreModel;
var
 i: Integer;
begin
 Name:= LowerCase(Name);

 for i:= 0 to Length(Data) - 1 do
  if (Name = LowerCase(Data[i].Name)) then
   begin
    Result:= Data[i];
    Exit;
   end;

 Result:= nil;  
end;

//---------------------------------------------------------------------------
function TAsphyreModels.Add(): TAsphyreModel;
var
 Index: Integer;
begin
 Index:= Length(Data);
 SetLength(Data, Length(Data) + 1);

 Data[Index]:= TAsphyreModel.Create(Self);
 Data[Index].FIndex:= Index;

 Result:= Data[Index];
end;

//---------------------------------------------------------------------------
function TAsphyreModels.Find(Model: TAsphyreModel): Integer;
var
 i: Integer;
begin
 for i:= 0 to Length(Data) - 1 do
  if (Data[i] = Model) then
   begin
    Result:= i;
    Exit;
   end;

 Result:= -1;
end;

//---------------------------------------------------------------------------
procedure TAsphyreModels.Remove(Index: Integer);
var
 i: Integer;
begin
 if (Index < 0)or(Index >= Length(Data)) then Exit;

 // release the model
 if (Data[Index] <> nil) then Data[Index].Free();

 // shift model list
 for i:= Index to Length(Data) - 2 do
  begin
   // shift the model
   Data[i]:= Data[i + 1];
   // update the index
   Data[i].FIndex:= i;
  end;

 // resize the list
 SetLength(Data, Length(Data) - 1);
end;

//---------------------------------------------------------------------------
procedure TAsphyreModels.RemoveAll();
var
 i: Integer;
begin
 for i:= 0 to Length(Data) - 1 do
  if (Data[i] <> nil) then
   begin
    Data[i].Free();
    Data[i]:= nil;
   end;

 SetLength(Data, 0);
end;

//---------------------------------------------------------------------------
function TAsphyreModels.HandleNotice(Msg: Cardinal): Boolean;
begin
 Result:= True;

 case Msg of
  msgBeginScene:
   FCamera:= nil;

  msgDeviceFinalize:
   RemoveAll();
 end;
end;

//---------------------------------------------------------------------------
function TAsphyreModels.AddFromFile(const Filename: string;
 Tag: Integer): Boolean;
var
 Model: TAsphyreModel;
begin
 // add a new model to the list
 Model:= Add();
 Model.FName:= ExtractFilename(Filename);

 // notify model creation
 if (Assigned(FOnModelCreate)) then
  FOnModelCreate(Self, Tag, Model);

 // try to load mesh data
 Result:= Model.LoadFromFile(Filename);

 // if unsuccessful, remove the model from list
 if (not Result) then Remove(Model.Index);
end;

//---------------------------------------------------------------------------
function TAsphyreModels.AddFromASDb(const Key: string; ASDb: TASDb;
 Tag: Integer): Boolean;
var
 Model: TAsphyreModel;
begin
 // add a new model to the list
 Model:= Add();
 Model.FName:= Key;

 // notify model creation
 if (Assigned(FOnModelCreate)) then
  FOnModelCreate(Self, Tag, Model);

 // try to load mesh data
 Result:= Model.LoadFromASDb(Key, ASDb);

 // if unsuccessful, remove the model from list
 if (not Result) then Remove(Model.Index);
end;

//---------------------------------------------------------------------------
end.

