{*******************************************************************************
*                                                                              *
*  ksPickers - wrapper for the picker interfaces                               *
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

unit ksPickers;

interface

{$IFDEF IOS}
{$DEFINE DPF}
{$ENDIF}

uses FMX.Pickers, Classes
  {$IFDEF DPF}
  ,DPF.iOS.UIActIonSheet
  {$ENDIF}
  ;

type
  TksSelectPickerItemEvent = procedure(Sender: TObject; AItem: string; AIndex: integer) of object;
  TksSelectPickerDateEvent = procedure(Sender: TObject; ADate: TDateTime) of object;
  TksSelectPickerTimeEvent = procedure(Sender: TObject; ATime: TDateTime) of object;

  TksPickerService = class
  private
    [weak]FPicker: TCustomListPicker;
    [weak]FDatePicker: TCustomDateTimePicker;
    [weak]FTimePicker: TCustomDateTimePicker;
    FPickerItems: TStrings;
    {$IFDEF DPF}
    FActionSheet: TDPFUIActionSheet;
    {$ENDIF}
    FPickerService: IFMXPickerService;

    FOnItemSelected: TksSelectPickerItemEvent;
    FOnDateSelected: TksSelectPickerDateEvent;
    FOnTimeSelected: TksSelectPickerDateEvent;
    //FOnItemSelected: TOnValueChanged;
    {$IFDEF DPF}
    procedure DoActionSheetButtonClick(Sender: TObject; ButtonIndex: Integer);
    procedure DoSelectItem(Sender: TObject; const AItemIndex: integer);
    {$ENDIF}
    procedure DoItemSelected(Sender: TObject; const AValueIndex: Integer);
    procedure DoDateSelected(Sender: TObject; const ADate: TDateTime);
    function CreateListPicker: TCustomListPicker;
    procedure DoTimeSelected(Sender: TObject; const ATime: TDateTime);
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure ShowActionSheet(AItems: array of string; ATitle: string; AOnSelect: TksSelectPickerItemEvent); overload;
    procedure ShowActionSheet(AItems: TStrings; ATitle: string; AOnSelect: TksSelectPickerItemEvent); overload;
    procedure ShowItemPicker(AItems: array of string; ATitle: string; AIndex: integer; AOnSelect: TksSelectPickerItemEvent); overload;
    procedure ShowItemPicker(AItems: TStrings; ATitle: string; AIndex: integer; AOnSelect: TksSelectPickerItemEvent); overload;
    procedure ShowDatePicker(ATitle: string; ASelected: TDateTime; AOnSelect: TksSelectPickerDateEvent); overload;
    procedure ShowTimePicker(ATitle: string; ASelected: TDateTime; AOnSelect: TksSelectPickerTimeEvent);
    function CreateDatePicker: TCustomDateTimePicker;
    procedure HidePickers;//nst AForce: Boolean = False);
  end;

var
  PickerService: TksPickerService;

implementation

uses FMX.Platform, SysUtils, FMX.Forms, System.Threading;

{ TksPickerService }

constructor TksPickerService.Create;
begin
  FPickerITems := TStringList.Create;
  {$IFDEF DPF}
  FActionSheet := TDPFUIActionSheet.Create(nil);
  {$ENDIF}
  if TPlatformServices.Current.SupportsPlatformService(IFMXPickerService, FPickerService) then
  begin
    FPicker := CreateListPicker;
    FDatePicker := CreateDatePicker;
    FTimePicker := CreateDatePicker;
    FTimePicker.ShowMode := TDatePickerShowMode.Time;
  end;
end;

function TksPickerService.CreateDatePicker: TCustomDateTimePicker;
begin
  Result := FPickerService.CreateDateTimePicker;

end;

function TksPickerService.CreateListPicker: TCustomListPicker;
begin
  Result := FPickerService.CreateListPicker;
  Result.Values.Clear;
end;

destructor TksPickerService.Destroy;
begin
  FPicker.DisposeOf;
  FreeAndNil(FPickerITems);
  {$IFDEF DPF}
  FActionSheet.DisposeOf;
  {$ENDIF}
  inherited;
end;

{$IFDEF DPF}
procedure TksPickerService.DoActionSheetButtonClick(Sender: TObject;
  ButtonIndex: Integer);
var
  ATask: ITask;
begin

  ATask := TTask.Create (procedure ()
   begin
     TThread.Synchronize(nil,procedure
                  begin
                     //Interact with UI
                      if ButtonIndex < FPickerITems.Count then
                        DoSelectItem(Sender, ButtonIndex);

                  end);
   end);
 ATask.Start;
end;
{$ENDIF}

procedure TksPickerService.DoDateSelected(Sender: TObject;
  const ADate: TDateTime);
begin
  if Assigned(FOnDateSelected) then
    FOnDateSelected(Self, ADate);
end;

procedure TksPickerService.DoTimeSelected(Sender: TObject;
  const ATime: TDateTime);
begin
  if Assigned(FOnTimeSelected) then
    FOnTimeSelected(Self, ATime);
end;

procedure TksPickerService.DoItemSelected(Sender: TObject;
  const AValueIndex: Integer);
begin
  if Assigned(FOnItemSelected) then
    FOnItemSelected(Sender,
                    FPickerITems[AValueIndex],
                    AValueIndex);
end;


{$IFDEF DPF}
procedure TksPickerService.DoSelectItem(Sender: TObject;
  const AItemIndex: integer);
begin
  if Assigned(FOnItemSelected) then
    FOnItemSelected(Sender, FPickerItems[AItemIndex], AItemIndex);
end;
{$ENDIF}

procedure TksPickerService.HidePickers;
begin
  FPickerService.CloseAllPickers;
end;

procedure TksPickerService.ShowActionSheet(AItems: array of string;
  ATitle: string; AOnSelect: TksSelectPickerItemEvent);
var
  ICount: integer;
  AStrings: TStrings;
begin
  HidePickers;
  AStrings := TStringList.Create;
  try
    for ICount := Low(AItems) to High(AItems) do
    begin
      AStrings.Add(AItems[ICount]);
    end;
    ShowActionSheet(AStrings, ATitle, AOnSelect);
  finally
    FreeAndNil(AStrings);
  end;
end;

procedure TksPickerService.ShowActionSheet(AItems: TStrings; ATitle: string;
  AOnSelect: TksSelectPickerItemEvent);
  {$IFDEF DPF}
var
  ICount: integer;
  ABtn: TDPFActionSheetButtonItem;
  {$ENDIF}
begin
  {$IFDEF DPF}
  //FActionSheet.OnClick := nil;
  FOnItemSelected := AOnSelect;

  FActionSheet := TDPFUIActionSheet.Create(nil);

  FActionSheet.Title := UpperCase(ATitle);
  FActionSheet.Buttons.Clear;
  FPickerITems.Assign(AItems);

  for ICount := 0 to AItems.Count-1 do
  begin
    ABtn := FActionSheet.Buttons.Add;
    ABtn.Title := UpperCase(AItems[ICount]);

  end;
  with FActionSheet.Buttons.Add do
  begin
    ButtonKind := TDPFActionSheetButtonKind.bkCancel;
    Title := 'CANCEL';
  end;

  FActionSheet.ShowMessage;
  FActionSheet.OnClick := DoActionSheetButtonClick;
  {$ELSE}
  ShowItemPicker(AItems, '', -1, AOnSelect);
  {$ENDIF}
end;

procedure TksPickerService.ShowDatePicker(ATitle: string;
  ASelected: TDateTime; AOnSelect: TksSelectPickerDateEvent);
begin
  FOnDateSelected := AOnSelect;
  FDatePicker.OnDateChanged := DoDateSelected;
  if ASelected = 0 then
    FDatePicker.Date := Date
  else
    FDatePicker.Date := ASelected;
  FDatePicker.Show;
end;

procedure TksPickerService.ShowTimePicker(ATitle: string;
  ASelected: TDateTime; AOnSelect: TksSelectPickerTimeEvent);
begin
  FOnTimeSelected := AOnSelect;
  FTimePicker.OnDateChanged := DoTimeSelected;
  FTimePicker.Date := ASelected;
  FTimePicker.Show;
end;

procedure TksPickerService.ShowItemPicker(AItems: TStrings; ATitle: string;
  AIndex: integer; AOnSelect: TksSelectPickerItemEvent);
begin
  FPickerITems.Assign(AItems);
  FPicker.Values.Assign(AItems);
  FPicker.ItemIndex := AIndex;
  FOnItemSelected := AOnSelect;
  FPicker.OnValueChanged := DoItemSelected;
  FPicker.Show;
end;

procedure TksPickerService.ShowItemPicker(AItems: array of string;
  ATitle: string; AIndex: integer; AOnSelect: TksSelectPickerItemEvent);
var
  ICount: integer;
  AStrings: TStrings;
begin
  AStrings := TStringList.Create;
  try
    for Icount := Low(AItems) to High(AItems) do
    begin
      AStrings.Add(AItems[ICount]);
      ShowItemPicker(AStrings, ATitle, AIndex, AOnSelect);
    end;
  finally
    FreeAndNil(AStrings);
  end;
end;

initialization

  PickerService := TksPickerService.Create;

finalization

  FreeAndNil(PickerService);

end.
