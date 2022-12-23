unit AsphyreReg;
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
 Classes, AsphyreDevices, AsphyreImages, AsphyreCanvas, AsphyreDb,
 AsphyreTimers, AsphyreFonts, AsphyreLights, AsphyreCameras, AsphyreMaterials,
 AsphyreTextures, AsphyreBillboards, AsphyreFacing, AsphyreFog, AsphyreKeyboard,
 AsphyreJoystick, AsphyreModels, AsphyreMouse, NetComs, MultiCanvas,
 AsphyreStates, AsphyreLandscapes, AsphyreParticles, AsphyreParticles3D,
 AsphyreLoader, AsphyreScreener, GuiBasic, NetExch;

//---------------------------------------------------------------------------
procedure Register();

//---------------------------------------------------------------------------
implementation

//---------------------------------------------------------------------------
procedure Register();
begin
 RegisterComponents('Asphyre', [TAsphyreDevice, TAsphyreTimer, TAsphyreCanvas,
  TMultiCanvas, TAsphyreImages, TAsphyreFonts, TASDb, TAsphyreLoader, TGuiBase,
  TAsphyreLights, TDeviceState, TAsphyreCamera, TAsphyreModels,
  TAsphyreMaterials, TAsphyreTextures, TAsphyreBB, TAsphyreFacing, TAsphyreFog,
  TAsphyreLandscape, TAsphyreParticles, TAsphyreParticles3D, TAsphyreKeyboard,
  TAsphyreMouse, TAsphyreJoysticks, TAsphyreScreener, TNetCom, TNetExchange]);
end;

//---------------------------------------------------------------------------
end.
