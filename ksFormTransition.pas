{*******************************************************************************
*                                                                              *
*  TksFormTransition - Push/Pop Form Queue Component                                *
*                                                                              *
*  https://bitbucket.org/gmurt/kscomponents                                    *
*                                                                              *
*  Copyright 2017 Graham Murt                                                  *
*                                                                              *
*  email: graham@kernow-software.co.uk                                         *
*                                                                              *
*  Licensed under the Apache License, Version 2.0 (the "License");             *
*  you may not use this file except in compliance with the License.            *
*  You may obtain a copy of the License at                                     *
*                                                                              *
*    http://www.apache.org/licenses/LICENSE-2.0                                *
*                                                                              *
*  Unless required by applicable law or agreed to in writing, software         *
*  distributed under the License is distributed on an "AS IS" BASIS,           *
*  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.    *
*  See the License for the specific language governing permissions and         *
*  limitations under the License.                                              *
*                                                                              *
*******************************************************************************}

unit ksFormTransition;

interface

{$I ksComponents.inc}

uses System.UITypes, FMX.Controls, FMX.Layouts, FMX.Objects, System.Classes,
  FMX.Types, Generics.Collections, FMX.Graphics, System.UIConsts, FMX.Effects,
  FMX.StdCtrls, System.Types, FMX.Forms, ksTypes, System.Generics.Collections;

const
  {$IFDEF ANDROID}
  C_TRANSITION_DURATION = 0.3;
  {$ELSE}
  C_TRANSITION_DURATION = 0.3;
  {$ENDIF}
  C_FADE_OPACITY = 0.5;

type
  TksTransitionMethod = (ksTmPush, ksTmPop);

  IksFormTransition = interface
  ['{34A12E50-B52C-4A49-B081-9CB67CA5FD6E}']
    procedure BeforeTransition(AType: TksTransitionMethod);
  end;

  TksTransitionType = (ksFtSlideInFromLeft,
                       ksFtSlideInFromTop,
                       ksFtSlideInFromRight,
                       ksFtSlideInFromBottom,
                       ksFtSlideOutToLeft,
                       ksFtSlideOutToTop,
                       ksFtSlideOutToRight,
                       ksFtSlideOutToBottom,
                       ksFtNoTransition);

  TksFormTransitionItem = class
    [weak]FFromForm: TCommonCustomForm;
    [weak]FToForm: TCommonCustomForm;
    FTransition: TksTransitionType;
  public
    property FromForm: TCommonCustomForm read FFromForm;
    property ToForm: TCommonCustomForm read FToForm;
    property Transition: TksTransitionType read FTransition;
  end;

  TksFormTransitionList = class(TObjectList<TksFormTransitionItem>)
  public

  end;

  [ComponentPlatformsAttribute(pidWin32 or pidWin64 or
    {$IFDEF XE8_OR_NEWER} pidiOSDevice32 or pidiOSDevice64
    {$ELSE} pidiOSDevice {$ENDIF} or pidiOSSimulator or pidAndroid)]

  TksFormTransition = class(TksComponent)
  private
    FInitalizedForms: TList<TCommonCustomForm>;

    function GetTransitionList: TksFormTransitionList;
    function TransitionExists(AFrom, ATo: TCommonCustomForm): Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function GetFormDepth(AForm: TCommonCustomForm): integer;
    procedure Push(AForm: TCommonCustomForm;
                   const ATransition: TksTransitionType = ksFtSlideInFromRight;
                   const ARecordPush: Boolean = True);
    procedure Pop;
    procedure PopAllForms;
    property TransitionList: TksFormTransitionList read GetTransitionList;
  end;

  //{$R *.dcr}

  procedure Push(AForm: TCommonCustomForm; const ATransition: TksTransitionType = ksFtSlideInFromRight; const ARecordPush: Boolean = True);
  procedure Pop;
  procedure ClearFormTransitionStack;

  procedure Register;

var
  ShowLoadingIndicatorOnTransition: Boolean;

implementation

uses FMX.Ani, SysUtils, ksCommon, DateUtils, ksFormTransitionUI, ksToolbar,
  ksPickers, ksLoadingIndicator;

var
  _InternalTransitionList: TksFormTransitionList;
  _InTransition: Boolean;

procedure Register;
begin
  RegisterComponents('Kernow Software FMX', [TksFormTransition]);
end;

procedure Push(AForm: TCommonCustomForm; const ATransition: TksTransitionType = ksFtSlideInFromRight; const ARecordPush: Boolean = True);
var
  ATran: TksFormTransition;
begin
  ATran := TksFormTransition.Create(nil);
  try
    ATran.Push(AForm, ATransition, ARecordPush);
  finally
    FreeAndNil(ATran);
  end;
end;

procedure Pop;
var
  ATran: TksFormTransition;
begin
  ATran := TksFormTransition.Create(nil);
  try
    ATran.Pop;
  finally
    FreeAndNil(ATran);
  end;
end;

procedure ClearFormTransitionStack;
begin
  _InternalTransitionList.Clear;
end;

{ TksFormTransition }

constructor TksFormTransition.Create(AOwner: TComponent);
begin
  inherited;
  FInitalizedForms := TList<TCommonCustomForm>.Create;

end;

destructor TksFormTransition.Destroy;
begin
  FreeAndNil(FInitalizedForms);
  inherited;
end;

function TksFormTransition.GetFormDepth(AForm: TCommonCustomForm): integer;
var
  ICount: integer;
begin
  Result := 0;
  for ICount := 0 to TransitionList.Count-1 do
  begin
    if TransitionList[ICount].ToForm = AForm then
    begin
      Result := ICount+1;
    end;
  end;
end;

function TksFormTransition.GetTransitionList: TksFormTransitionList;
begin
  Result := _InternalTransitionList;
end;

procedure TksFormTransition.Pop;
var
  AInfo: TksFormTransitionItem;
  AFrom, ATo: TCommonCustomForm;
  AAnimateForm: TfrmFormTransitionUI;
  AFormIntf: IksFormTransition;
begin

  Screen.ActiveForm.Focused := nil;

  if _InternalTransitionList.Count < 1 then
    Exit;

  if _InTransition then
    Exit;
  _InTransition := True;

  AInfo := _InternalTransitionList.Last;
  AFrom := AInfo.FToForm;
  ATo := AInfo.FFromForm;

  if ShowLoadingIndicatorOnTransition then
    ShowLoadingIndicator(AFrom);
  try




    AAnimateForm := TfrmFormTransitionUI.Create(nil);
    try




      if Supports(ATo, IksFormTransition, AFormIntf) then
        AFormIntf.BeforeTransition(ksTmPop);

      AAnimateForm.Initialise(AFrom, ATo);
      AAnimateForm.Visible := True;



      AAnimateForm.Animate(AInfo.FTransition, True);
      ATo.Visible := True;
      AAnimateForm.Visible := False;


      AFrom.Visible := False;
      ATo.Activate;

      {$IFDEF MSWINDOWS}
      ATo.SetBounds(AFrom.Left, AFrom.Top, AFrom.Width, AFrom.Height);
      {$ENDIF}

      _InternalTransitionList.Delete(_InternalTransitionList.Count-1);
    finally
      AAnimateForm.DisposeOf;
    end;
  finally
    if ShowLoadingIndicatorOnTransition then
      HideLoadingIndicator(AFrom);

    _InTransition := False;
  end;




end;

procedure TksFormTransition.PopAllForms;
var
  AInfo: TksFormTransitionItem;
  AFrom, ATo: TCommonCustomForm;
  AAnimateForm: TfrmFormTransitionUI;
  AFormIntf: IksFormTransition;
begin
  if _InternalTransitionList.Count = 0 then
    Exit;

  if _InTransition then
    Exit;
  _InTransition := True;
  try
    AAnimateForm := TfrmFormTransitionUI.Create(nil);
    try

      AInfo := _InternalTransitionList.Last;

      AFrom := AInfo.FToForm;
      ATo := _InternalTransitionList.First.FFromForm;

      if Supports(ATo, IksFormTransition, AFormIntf) then
        AFormIntf.BeforeTransition(ksTmPop);

      AAnimateForm.Initialise(AFrom, ATo);
      AAnimateForm.Visible := True;

      AAnimateForm.Animate(AInfo.FTransition, True);
      ATo.Visible := True;
      AAnimateForm.Visible := False;


      AFrom.Visible := False;
      ATo.Activate;

      {$IFDEF MSWINDOWS}
      ATo.SetBounds(AFrom.Left, AFrom.Top, AFrom.Width, AFrom.Height);
      {$ENDIF}

      _InternalTransitionList.Clear;//(_InternalTransitionList.Count-1);
    finally
      AAnimateForm.DisposeOf;
    end;
  finally
    _InTransition := False;
  end;
end;

procedure TksFormTransition.Push(AForm: TCommonCustomForm;
  const ATransition: TksTransitionType = ksFtSlideInFromRight;
  const ARecordPush: Boolean = True);
var
  AInfo: TksFormTransitionItem;
  AFrom, ATo: TCommonCustomForm;
  AAnimateForm: TfrmFormTransitionUI;
  AFormIntf: IksFormTransition;
begin
  if _InTransition then
    Exit;

  AFrom := Screen.ActiveForm;
  ATo := AForm;
  _InTransition := True;
  if ShowLoadingIndicatorOnTransition then
    ShowLoadingIndicator(AFrom);
  try
    PickerService.HidePickers;



    {$IFDEF ANDROID}
    // fix for Android initial form size
    if FInitalizedForms.IndexOf(AFrom) = -1 then
      FInitalizedForms.Add(AFrom);

    if FInitalizedForms.IndexOf(ATo) = -1 then
    begin
      ATo.Visible := True;
      ATo.Visible := False;
      FInitalizedForms.Add(ATo);
    end;
    {$ENDIF}


    if (AFrom = ATo) then
      Exit;

    if TransitionExists(AFrom, ATo) then
      Exit;


    if Supports(ATo, IksFormTransition, AFormIntf) then
      AFormIntf.BeforeTransition(ksTmPush);

    AInfo := TksFormTransitionItem.Create;
    AInfo.FFromForm := AFrom;
    AInfo.FToForm := ATo;
    AInfo.FTransition := ATransition;
    if ARecordPush then
      _InternalTransitionList.Add(AInfo);

    AAnimateForm := TfrmFormTransitionUI.Create(nil);
    try


      AAnimateForm.Initialise(AFrom, ATo);
      AAnimateForm.Visible := True;
      AAnimateForm.Animate(AInfo.FTransition, False);
      AForm.Visible := True;
      AAnimateForm.Visible := False;
      AFrom.Visible := False;
      AForm.Activate;
      {$IFDEF MSWINDOWS}
      AForm.SetBounds(AFrom.Left, AFrom.Top, AFrom.Width, AFrom.Height);
      {$ENDIF}
    finally
      AAnimateForm.DisposeOf;
    end;

  finally
    if not ARecordPush then
      FreeAndNil(AInfo);
    _InTransition := False;
    if ShowLoadingIndicatorOnTransition then
      HideLoadingIndicator(AFrom);
  end;
end;

function TksFormTransition.TransitionExists(AFrom,
  ATo: TCommonCustomForm): Boolean;
var
  ICount: integer;
  AItem: TksFormTransitionItem;
begin
  Result := False;
  for ICount := 0 to GetTransitionList.Count-1 do
  begin
    AItem := GetTransitionList.Items[ICount];
    if (AItem.FromForm = AFrom) and (AItem.ToForm = ATo) then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

initialization

  {$IFDEF IOS}
  ShowLoadingIndicatorOnTransition := True;
  {$ELSE}
  ShowLoadingIndicatorOnTransition := False;
  {$ENDIF}

  _InternalTransitionList := TksFormTransitionList.Create(True);
  _InTransition := False;

finalization

  FreeAndNil(_InternalTransitionList);

end.



