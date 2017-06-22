{*******************************************************************************
*                                                                              *
*  TksVirtualListView                                                          *
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
*  See the License forthe specific language governing permissions and          *
*  limitations under the License.                                              *
*                                                                              *
*******************************************************************************}

unit ksVirtualListView;

interface

{$I ksComponents.inc}


uses System.Classes, System.Types, ksTypes, FMX.Graphics, System.UITypes,
  System.Generics.Collections, FMX.Types, FMX.InertialMovement, System.UIConsts,
  FMX.StdCtrls, FMX.Controls, FMX.Platform, FMX.Objects, FMX.Edit,
  FMX.TextLayout;

const
  C_VLIST_ITEM_DEFAULT_HEIGHT = 44;
  C_VLIST_HEADER_DEFAULT_HEIGHT = 38;

  C_VLIST_DEFAULT_SELECTED_COLOR = $FFE9E9E9;

  C_VLIST_CACHE_COUNT = 100;
  C_LONG_TAP_DURATION = 400;

{$IFDEF MSWINDOWS}
  C_VLIST_SCROLLBAR_WIDTH = 16;
{$ELSE}
  C_VLIST_SCROLLBAR_WIDTH = 8;
{$ENDIF}
  C_ACCESSORY_WIDTH = 12;

type
  TksVListItem = class;
  TksVListItemList = class;
  TksVirtualListView = class;
  TksVListActionButton = class;
  TksVListActionButtons = class;

  TksSelectionType = (ksSingleSelect, ksMultiSelect);
  TksVListCheckBoxAlign = (ksCbLeftAlign, ksCbRightAlign);
  TksVListActionButtonAlign = (ksAbLeftAlign, ksAbRightAlign);
  TksVListSwipeDirection = (ksSwipeFromLeft, ksSwipeFromRight);
  TksVListItemPurpose = (None, Header);
  TksVListItemState = (Normal, Deleting, Deleted, Sliding);
  TksVListItemSelectorType = (ksSelectorNone, ksSelectorEdit, ksSelectorPicker, ksSelectorDate, ksSelectorTime);
  TksImageShape = (ksImageRect, ksImageCircle);

  TksVListItemClickEvent = procedure(Sender: TObject; AItem: TksVListItem) of object;
  TksVListItemLongTapEvent = procedure(Sender: TObject; AItem: TksVListItem) of object;
  TksVListItemSwipeEvent = procedure(Sender: TObject; ARow: TksVListItem; ASwipeDirection: TksVListSwipeDirection; AButtons: TksVListActionButtons)  of object;
  TksVListDeletingItemEvent = procedure(Sender: TObject; AItem: TksVListItem; var ACanDelete: Boolean) of object;
  TksItemActionButtonClickEvent = procedure(Sender: TObject; ARow: TksVListItem; AButton: TksVListActionButton) of object;
  TksItemEditInputEvent = procedure(Sender: TObject; ARow: TksVListItem; AText: string) of object;

  TksItemBeforeSelectPickerItemEvent = procedure(Sender: TObject; ARow: TksVListItem; var AText: string) of object;
  TksItemSelectPickerItemEvent = procedure(Sender: TObject; ARow: TksVListItem; AText: string) of object;

  TksItemDateSelectedEvent = procedure(Sender: TObject; ARow: TksVListItem; ADate: TDateTime) of object;
  TksItemTimeSelectedEvent = procedure(Sender: TObject; ARow: TksVListItem; ATime: TDateTime) of object;
  TksItemGetPickerItemsEvent = procedure(Sender: TObject; ARow: TksVListItem; var ASelected: string; AItems: TSTrings) of object;


  TksVirtualListViewAppearence = class(TPersistent)
  private
    [weak]FListView: TksVirtualListView;
    FBackground: TAlphaColor;
    FItemBackground: TAlphaColor;
    FSeparatorColor: TAlphaColor;
    FHeaderColor: TAlphaColor;
    FHeaderFontColor: TAlphaColor;
    FSelectedColor: TAlphaColor;
    FSelectedFontColor: TAlphaColor;
    procedure SetBackground(const Value: TAlphaColor);
    procedure SetItemBackground(const Value: TAlphaColor);
    procedure SetSeparatorBackground(const Value: TAlphaColor);
    procedure SetHeaderColor(const Value: TAlphaColor);
    procedure SetSelectedColor(const Value: TAlphaColor);
    procedure SetSelectedFontColor(const Value: TAlphaColor);
    procedure SetHeaderFontColor(const Value: TAlphaColor);
  public
    constructor Create(AListView: TksVirtualListView);
    destructor Destroy; override;
    procedure Assign(ASource: TPersistent); override;
  published
    property Background: TAlphaColor read FBackground write SetBackground default claWhite;
    property HeaderColor: TAlphaColor read FHeaderColor write SetHeaderColor default claNull;
    property HeaderFontColor: TAlphaColor read FHeaderFontColor write SetHeaderFontColor default claNull;
    property SeparatorColor: TAlphaColor read FSeparatorColor write SetSeparatorBackground default claDarkgray;
    property ItemBackground: TAlphaColor read FItemBackground write SetItemBackground default claWhite;
    property SelectedColor: TAlphaColor read FSelectedColor write SetSelectedColor default C_VLIST_DEFAULT_SELECTED_COLOR;
    property SelectedFontColor: TAlphaColor read FSelectedFontColor write SetSelectedFontColor default claNull;
  end;

  TksVListActionButton = class
  strict private
    FWidth: integer;
    FIcon: TBitmap;
    FTextColor: TAlphaColor;
    FColor: TAlphaColor;
    FText: string;
    FIsDeleteButton: Boolean;
    FAccessory: TksAccessoryType;
  private
    FButtonRect: TRectF;
    procedure SetAccessory(const Value: TksAccessoryType);
  private
    procedure SetTextColor(const Value: TAlphaColor);
  public
    constructor Create(AIsDelete: Boolean);
    destructor Destroy; override;
    procedure DrawToCanvas(ACanvas: TCanvas; ARect: TRectF);
    property Accessory: TksAccessoryType read FAccessory write SetAccessory;
    property Text: string read FText write FText;
    property TextColor: TAlphaColor read FTextColor write SetTextColor default claWhite;
    property Color: TAlphaColor read FColor write FColor;
    property Width: integer read FWidth write FWidth default 80;
    property IsDeleteButton: Boolean read FIsDeleteButton write FIsDeleteButton;
  end;

  TksVListActionButtons = class(TObjectList<TksVListActionButton>)
  strict private
    FAlignment: TksVListActionButtonAlign;
  private
    function GetTotalWidth: integer;
  public
    constructor Create(AOwner: TksVListItem);
    procedure DrawToCanvas(ACanvas: TCanvas; ARect: TRectF);
    function AddButton(AText: string; AColor, ATextColor: TAlphaColor;
      const AIcon: TksAccessoryType = atNone; const AWidth: integer = 60): TksVListActionButton;
    function ButtonAtXY(x, y: single): TksVListActionButton;
    property Alignment: TksVListActionButtonAlign read FAlignment
      write FAlignment;
    property TotalWidth: integer read GetTotalWidth;
  end;

  TksVListCheckBoxOptions = class(TPersistent)
  private
    [weak]
    FOwner: TksVirtualListView;
    FVisible: Boolean;
    FMode: TksSelectionType;
    FAlignment: TksVListCheckBoxAlign;
    procedure SetAlignment(const Value: TksVListCheckBoxAlign);
    procedure SetMode(const Value: TksSelectionType);
    procedure SetVisible(const Value: Boolean);
    procedure Changed;
  public
    constructor Create(AOwner: TksVirtualListView); virtual;
  published
    property Visible: Boolean read FVisible write SetVisible default False;
    property Mode: TksSelectionType read FMode write SetMode
      default ksSingleSelect;
    property Alignment: TksVListCheckBoxAlign read FAlignment write SetAlignment
      default ksCbRightAlign;
  end;

  TksVListSelectionOptions = class(TPersistent)
  private
    [weak]
    FOwner: TksVirtualListView;
    FKeepSelection: Boolean;
    FSelectionType: TksSelectionType;
    procedure SetKeepSelection(const Value: Boolean);
    procedure SetSelectionType(const Value: TksSelectionType);
    procedure Changed;
  public
    constructor Create(AOwner: TksVirtualListView); virtual;
  published
    property KeepSelection: Boolean read FKeepSelection write SetKeepSelection
      default False;
    property SelectionType: TksSelectionType read FSelectionType
      write SetSelectionType default ksSingleSelect;
  end;

  TksVListItemBaseObject = class(TPersistent)
  private
    [weak]
    FOwner: TksVListItem;
    FID: string;
    FVertAlign: TVerticalAlignment;
    FHorzAlign: TAlignment;
    FLeft: single;
    FTop: single;
    FWidth: single;
    FHeight: single;
    FVisible: Boolean;
    FUsePercentForXPos: Boolean;
    FOnChange: TNotifyEvent;
    procedure SetVertAlign(const Value: TVerticalAlignment);
    procedure SetHeight(const Value: single);
    procedure SetLeft(const Value: single);
    procedure SetTop(const Value: single);
    procedure SetWidth(const Value: single);
    procedure SetHorzAlign(const Value: TAlignment);
    procedure SetVisible(const Value: Boolean);
    procedure SetUsePercentForXPos(const Value: Boolean);
  protected
    function CalcObjectRect(AItemRect: TRectF): TRectF; virtual;
    procedure Changed; virtual;
    procedure DrawToCanvas(ACanvas: TCanvas; AItemRect: TRectF); virtual;
  public
    constructor Create(AItem: TksVListItem); virtual;
    procedure ClearCache; virtual;
    property Left: single read FLeft write SetLeft;
    property Top: single read FTop write SetTop;
    property Width: single read FWidth write SetWidth;
    property Height: single read FHeight write SetHeight;
    property HorzAlign: TAlignment read FHorzAlign write SetHorzAlign;
    property VertAlign: TVerticalAlignment read FVertAlign write SetVertAlign default TVerticalAlignment.taVerticalCenter;
    property UsePercentForXPos: Boolean read FUsePercentForXPos write SetUsePercentForXPos default False;
    property ID: string read FID write FID;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property Visible: Boolean read FVisible write SetVisible default True;
  end;

  TksVListItemTextObject = class(TksVListItemBaseObject)
  private
    {$IFDEF IOS}
    FCached: TBitmap;
    {$ENDIF}
    //FCachedSize: TRectF;
    FTextSize: TPointF;
    //FTextRect: TRectF;
    FTextLayout: TTextLayout;
    FTextSettings: TTextSettings;
    FText: string;
    FMaxWidth: integer;
    FActualTextWidth: single;
    procedure SetText(const Value: string);
    function GetFont: TFont;
    procedure SetFont(const Value: TFont);
    procedure SetMaxWidth(const Value: integer);
  protected
    procedure Changed; override;
    function ActualTextWidth: single;
    function CalculateSize: TSizeF;
    procedure BeforeRenderText(ACanvas: TCanvas; ARect: TRectF); virtual;
  public
    constructor Create(AItem: TksVListItem); override;
    destructor Destroy; override;
    procedure ClearCache; override;
    function CalculateWidth: single;
    procedure DrawToCanvas(ACanvas: TCanvas; AItemRect: TRectF); override;
    property Text: string read FText write SetText;
    property TextSettings: TTextSettings read FTextSettings;
    property Font: TFont read GetFont write SetFont;
    property MaxWidth: integer read FMaxWidth write SetMaxWidth default 0;
  end;

  TksVListItemShapeObject = class(TksVListItemBaseObject)
  private
    FStroke: TStrokeBrush;
    FFill: TBrush;
    FCornerRadius: single;
  public
    constructor Create(AItem: TksVListItem); override;
    destructor Destroy; override;
    procedure DrawToCanvas(ACanvas: TCanvas; AItemRect: TRectF); override;
    property CornerRadius: single read FCornerRadius write FCornerRadius;
  end;

  TksVListItemBubbleObject = class(TksVListItemTextObject)
  private
    FColor: TAlphaColor;
    FTextColor: TAlphaColor;
    FSender: string;
    procedure SetColor(const Value: TAlphaColor);
    procedure SetTextColor(const Value: TAlphaColor);
  public
    constructor Create(AItem: TksVListItem); override;
    property Color: TAlphaColor read FColor write SetColor;
    property TextColor: TAlphaColor read FTextColor write SetTextColor;
    property Sender: string read FSender write FSender;


  end;

  TksVListItemImageObject = class(TksVListItemBaseObject)
  private
    FBitmap: TBitmap;
    FRenderImage: TBitmap;
    //FCached: TBitmap;
    //FOwnsImage: Boolean;
    FBackground: TAlphaColor;
    FOpacity: single;
    FImageShape: TksImageShape;
    function GetIsEmpty: Boolean;
    procedure SetBackground(const Value: TAlphaColor);
    procedure SetOpacity(const Value: single);
    procedure SetImageShape(const Value: TksImageShape);
  protected
    procedure SetBitmap(const Value: TBitmap); virtual;
  public
    constructor Create(AItem: TksVListItem); override;
    destructor Destroy; override;
    procedure DrawToCanvas(ACanvas: TCanvas; AItemRect: TRectF); override;
    procedure SetProperties(ABitmap: TBitmap; AOpaqueColor, ABackgroundColor: TAlphaColor);
    procedure SetOpaqueColor(AColor: TAlphaColor);
    property IsEmpty: Boolean read GetIsEmpty;
    property Bitmap: TBitmap read FBitmap write SetBitmap;
    property Background: TAlphaColor read FBackground write SetBackground;
    property Opacity: single read FOpacity write SetOpacity;
    property ImageShape: TksImageShape read FImageShape write SetImageShape;
  end;

  TksVListItemAccessoryObject = class(TksVListItemImageObject)
  private
    FAccessoryType: TksAccessoryType;
    FColor: TAlphaColor;
    procedure RedrawAccessory;
    procedure SetAccessoryType(const Value: TksAccessoryType);
    //procedure SetColor(const Value: TAlphaColor);
  protected
    //procedure SetBitmap(const Value: TBitmap); override;
  public
    constructor Create(AItem: TksVListItem); override;
    procedure DrawToCanvas(ACanvas: TCanvas; AItemRect: TRectF); override;
    property AccessoryType: TksAccessoryType read FAccessoryType write SetAccessoryType default atNone;
    //property Color: TAlphaColor read FColor write SetColor default claNull;
  end;

  TksVListObjectList = class(TObjectList<TksVListItemBaseObject>)
  public
    procedure ClearCache;
  end;

  TksVListItem = class // (TFmxObject)
  private
    [weak]FOwner: TksVListItemList;
    // FCachedRow: TBitmap;
    FBackground: TAlphaColor;
    FCanSelect: Boolean;
    FChecked: Boolean;
    FHeight: integer;
    FSelected: Boolean;
    FItemRect: TRectF;
    FImage: TksVListItemImageObject;
    FTitle: TksVListItemTextObject;
    FSubTitle: TksVListItemTextObject;
    FDetail: TksVListItemTextObject;
    FAccessory: TksVListItemAccessoryObject;
    FActionButtons: TksVListActionButtons;
    FOffset: integer;
    FChanged: Boolean;
    FUpdateCount: integer;
    FAbsoluteIndex: integer;
    FIndex: integer;
    FSwipeCalc: TAniCalculations;
    FDeleteCalc: TAniCalculations;
    FTagInt: integer;
    FPurpose: TksVListItemPurpose;
    FState: TksVListItemState;
    FIconSize: integer;
    // events
    FOnClick: TNotifyEvent;
    FObjects: TksVListObjectList;
    FTagStr: string;
    FCheckBoxVisible: Boolean;
    //FPickerService: IFMXPickerService;
    //FPicker: TCustomListPicker;
    FOnEditInput: TksItemEditInputEvent;
    FBeforeSelectPickerItem: TksItemBeforeSelectPickerItemEvent;
    FOnSelectPickerItem: TksItemSelectPickerItemEvent;
    //FOnSelectPickerDate: TksItemSelectPickerDateEvent;
    FSelectedDate: TDateTime;
    FSelectedTime: TDateTime;
    FSelectedItem: string;
    FEditFieldKeyboardType: TVirtualKeyboardType;
    FSelectorType: TksVListItemSelectorType;
    FOnDateSelected: TksItemDateSelectedEvent;
    FOnTimeSelected: TksItemTimeSelectedEvent;
    // procedure CacheRowToBitmap;
    procedure Changed;
    procedure SetAccessory(const Value: TksVListItemAccessoryObject);
    procedure SetDetail(const Value: TksVListItemTextObject);
    procedure SetImage(const Value: TksVListItemImageObject);
    procedure SetTitle(const Value: TksVListItemTextObject);
    procedure SetHeight(const Value: integer);
    procedure UpdateStandardObjectPositions;
    procedure SetSelected(const Value: Boolean);
    procedure SelectItem(ADeselectAfter: integer);
    procedure SetChecked(const Value: Boolean);
    procedure SetSubTitle(const Value: TksVListItemTextObject);
    procedure SetBackground(const Value: TAlphaColor);
    // procedure SetOffset(const Value: integer);
    procedure DeleteItem;
    procedure SlideOut(ADirection: TksVListSwipeDirection);
    procedure SlideIn;
    procedure SwipeCalcChange(Sender: TObject);
    procedure DeleteCalcChange(Sender: TObject);
    function CreateAniCalc(AOnChange: TNotifyEvent): TAniCalculations;
    procedure DoClicked(var AHandled: Boolean);
    procedure SetPurpose(const Value: TksVListItemPurpose);
    procedure SetOffset(const Value: integer);
    procedure SetCanSelect(const Value: Boolean);
    procedure SetIconSize(const Value: integer);
    //procedure DoDatePickerChanged(Sender: TObject; const ADateTime: TDateTime);
    procedure DoItemPickerChanged(Sender: TObject; AItem: string; AValueIndex: Integer);
    procedure DoDatePickerChanged(Sender: TObject; ADate: TDateTime);

    procedure ShowEditInput;
    procedure ShowDatePicker(ASelected: TDateTime);
    procedure ShowTimePicker(ASelected: TDateTime);
    procedure ShowPicker;
    procedure DoTimePickerChanged(Sender: TObject; ATime: TDateTime);
  public
    constructor Create(Owner: TksVListItemList); virtual;
    destructor Destroy; override;
    function IsItemVisible(AViewPort: TRectF): Boolean;
    function AddText(x, y: single; AText: string): TksVListItemTextObject; overload;
    function AddText(x, y, AWidth: single; AText: string): TksVListItemTextObject; overload;
    function AddImage(x, y, AWidth, AHeight: single; ABitmap: TBitmap): TksVListItemImageObject;
    function DrawRect(x, y, AWidth, AHeight, ACornerRadius: single; AStroke, AFill: TAlphaColor): TksVListItemShapeObject;
    function AddChatBubble(AText, ASender: string; ALeftAlign: Boolean): TksVListItemBubbleObject;
    //procedure BeginUpdate;
    ///procedure EndUpdate;
    //procedure CacheItem;
    //procedure ClearCache;

    // procedure ShowActionButtons(AAlign: TksVListActionButtonAlign);
    // procedure HideActionButtons;
    procedure DrawToCanvas(ACanvas: TCanvas; AScrollPos: single; ADrawToCache: Boolean);
    property AbsoluteIndex: integer read FAbsoluteIndex;
    property Index: integer read FIndex;
    property Background: TAlphaColor read FBackground write SetBackground default claNull;
    property CanSelect: Boolean read FCanSelect write SetCanSelect default True;
    property Checked: Boolean read FChecked write SetChecked default False;
    property Height: integer read FHeight write SetHeight;
    property Image: TksVListItemImageObject read FImage write SetImage;
    property Title: TksVListItemTextObject read FTitle write SetTitle;
    property SubTitle: TksVListItemTextObject read FSubTitle write SetSubTitle;
    property Detail: TksVListItemTextObject read FDetail write SetDetail;
    property Accessory: TksVListItemAccessoryObject read FAccessory
      write SetAccessory;
    property ItemRect: TRectF read FItemRect;
    property Selected: Boolean read FSelected write SetSelected;
    property Purpose: TksVListItemPurpose read FPurpose write SetPurpose
      default None;
    property TagInt: integer read FTagInt write FTagInt default 0;
    property TagStr: string read FTagStr write FTagStr;
    property State: TksVListItemState read FState write FState default Normal;
    property Offset: integer read FOffset write SetOffset default 0;
    property IconSize: integer read FIconSize write SetIconSize default 28;
    property SelectedDate: TDateTime read FSelectedDate write FSelectedDate;
    // events...
    property OnClick: TNotifyEvent read FOnClick write FOnClick;
    property CheckBoxVisible: Boolean read FCheckBoxVisible write FCheckBoxVisible default True;
    property SelectorType: TksVListItemSelectorType read FSelectorType write FSelectorType default ksSelectorNone;
    property EditFieldKeyboardType: TVirtualKeyboardType read FEditFieldKeyboardType write FEditFieldKeyboardType default TVirtualKeyboardType.Alphabet;
    property OnEditInput: TksItemEditInputEvent read FOnEditInput write FOnEditInput;
    property BeforeSelectPickerItem: TksItemBeforeSelectPickerItemEvent read FBeforeSelectPickerItem write FBeforeSelectPickerItem;
    property OnSelectPickerItem: TksItemSelectPickerItemEvent read FOnSelectPickerItem write FOnSelectPickerItem;
    //property OnSelectPickerDate: TksItemSelectPickerDateEvent read FOnSelectPickerDate write FOnSelectPickerDate;
    property OnDateSelected: TksItemDateSelectedEvent read FOnDateSelected write FOnDateSelected;
    property OnTimeSelected: TksItemTimeSelectedEvent read FOnTimeSelected write FOnTimeSelected;

  end;

  TksVListItemList = class(tobjectlist<tksvlistitem>)
  private
    [weak]FOwner: TksVirtualListView;
    //FItems: TObjectList<TksVListItem>;
    procedure UpdateItemRects;
    procedure Changed(AUpdateScrollLimits: Boolean);
   // function GetItem(index: integer): TksVListItem;
    //function GetCount: integer;
    function GetCheckedCount: integer;

  public
    constructor Create(AOwner: TksVirtualListView); virtual;
    destructor Destroy; override;

    function Add: TksVListItem; overload;
    function Add(ATitle, ASubTitle, ADetail: string; const AAccessory: TksAccessoryType = atNone): TksVListItem; overload;
    function Add(ATitle, ASubTitle, ADetail: string; AImage: TBitmap; const AAccessory: TksAccessoryType = atNone): TksVListItem; overload;
    function AddPickerSelector(ATitle, ASubTitle, ADetail: string; AImage: TBitmap; ATagStr: string): TksVListItem;
    function AddDateSelector(ATitle, ASubTitle: string; ASelected: TDateTime; AImage: TBitmap; ATagStr: string): TksVListItem;
    function AddTimeSelector(ATitle, ASubTitle: string; ASelected: TDateTime; AImage: TBitmap; ATagStr: string): TksVListItem;
    function AddInputSelector(ATitle, ASubTitle, ADetail, ATagStr: string): TksVListItem;
    function AddHeader(AText: string): TksVListItem;
    function AddChatBubble(AText, ASender: string; AColor, ATextColor: TAlphaColor; ALeftAlign: Boolean): TksVListItem;
    function Insert(AIndex: integer; ATitle, ASubTitle, ADetail: string; const AAccessory: TksAccessoryType = atNone): TksVListItem;
    function ItemAtPos(x, y: single): TksVListItem;

    procedure Clear;
    procedure Delete(AIndex: integer; AAnimate: Boolean); overload;
    procedure Delete(AItem: TksVListItem; const AAnimate: Boolean = False); overload;
   // property Count: integer read GetCount;
    property CheckedCount: integer read GetCheckedCount;
    //property Items[index: integer]: TksVListItem read GetItem; default;
  //  function IndexOf(AItem: TksVListItem): integer;
  end;

  TksVListPullToRefreshOptions = class(TPersistent)
  private
    FPullText: string;
    FReleaseText: string;
    FEnabled: Boolean;
  public
    constructor Create; virtual;
  published
    property PullText: string read FPullText write FPullText;
    property ReleaseText: string read FReleaseText write FReleaseText;
    property Enabled: Boolean read FEnabled write FEnabled default False;
  end;

  TksVListDeleteButton = class(TPersistent)
  private
    FEnabled: Boolean;
    FText: string;
    FColor: TAlphaColor;
    FTextColor: TAlphaColor;
    FWidth: integer;
    FShowImage: Boolean;
  public
    constructor Create; virtual;
  published
    property Color: TAlphaColor read FColor write FColor default claRed;
    property TextColor: TAlphaColor read FTextColor write FTextColor default claWhite;
    property Enabled: Boolean read FEnabled write FEnabled default False;
    property Text: string read FText write FText;
    property ShowImage: Boolean read FShowImage write FShowImage default True;
    property Width: integer read FWidth write FWidth default 60;
  end;

  TksNoItemsText = class(TPersistent)
  private
    [weak]FOwner: TksVirtualListView;
    FEnabled: Boolean;
    FTextColor: TAlphaColor;
    FFont: TFont;
    FText: string;
    procedure Changed;
    procedure SetEnabled(const Value: Boolean);
    procedure SetFont(const Value: TFont);
    procedure SetText(const Value: string);

  public
    constructor Create(AListView: TksVirtualListView); virtual;
    destructor Destroy; override;
    procedure DrawToCanvas(ACanvas: TCanvas; ARect: TRectF);
  published
    property Enabled: Boolean read FEnabled write SetEnabled default False;
    property Text: string read FText write SetText;
    property Font: TFont read FFont write SetFont;
    property TextColor: TAlphaColor read FTextColor write FTextColor default claSilver;
  end;

  TksScrollBar = class(TScrollBar)
  public
    constructor Create(AOwner: TComponent); override;
  end;


  [ComponentPlatformsAttribute(pidWin32 or pidWin64 or
{$IFDEF XE8_OR_NEWER} pidiOSDevice32 or pidiOSDevice64
{$ELSE} pidiOSDevice {$ENDIF} or pidiOSSimulator or pidAndroid)]

  TksVirtualListView = class(TksControl)
  private
    FAniCalc: TksAniCalc;
    FAppearence: TksVirtualListViewAppearence;
    FCheckBoxOptions: TksVListCheckBoxOptions;
    FItems: TksVListItemList;
    FScrollPos: integer;
    FScrollBar: TksScrollBar;
    FOnScroll: TNotifyEvent;
    FTotalItemHeight: single;
    FMouseDownPos: TPointF;
    FMaxScrollPos: integer;
    FUpdateCount: integer;
    FMouseDownTime: TDateTime;
    FSelectionOptions: TksVListSelectionOptions;
    FPendingRefresh: Boolean;
    FOnPullRefresh: TNotifyEvent;
    FTimerService: IFMXTimerService;
    FLongTapTimer: TFmxHandle;
    FDeletedItemCleanup: TFmxHandle;
    FMousePt: TPointF;
    FMouseDownItem: TksVListItem;
    FEventService: IFMXApplicationEventService;
    // FActionButtons: TksVListActionButtons;
    FPullToRefresh: TksVListPullToRefreshOptions;
    FDeleteButton: TksVListDeleteButton;
    FItemHeight: integer;
    FItemIndex: integer;
    FPullRefreshTimer: TFmxHandle;

    //FEventThread: TThread;
    FRefreshing: Boolean;

    // events...
    FOnItemClick: TksVListItemClickEvent;
    FOnItemLongTap: TksVListItemLongTapEvent;
    FOnItemSwipe: TksVListItemSwipeEvent;
    FOnItemDeleted: TNotifyEvent;
    FCanDeleteItem: TksVListDeletingItemEvent;
    FHeaderHeight: integer;
    FNoItemsText: TksNoItemsText;
    FFocusedControl: TControl;
    FOnActionButtonClick: TksItemActionButtonClickEvent;
    FOnItemEditInputEvent: TksItemEditInputEvent;
    FOnItemDateSelectedEvent: TksItemDateSelectedEvent;
    FOnItemTimeSelectedEvent: TksItemTimeSelectedEvent;
    FBeforeItemPickerSelectedEvent: TksItemBeforeSelectPickerItemEvent;
    FOnItemPickerSelectedEvent: TksItemSelectPickerItemEvent;
    FOnGetPickerItemsEvent: TksItemGetPickerItemsEvent;
    //FFont: TFont;
    procedure SetScrollPos(const Value: integer);
    procedure AniCalcChange(Sender: TObject);
    procedure AniCalcStart(Sender: TObject);
    procedure AniCalcStop(Sender: TObject);
    function GetViewport: TRectF;
    //procedure CacheItems(AStartIndex, AEndIndex: integer);
    // procedure UpdateOverlayPosition;
    procedure SetCheckBoxOptions(const Value: TksVListCheckBoxOptions);
    procedure ScrollBarChanged(Sender: TObject);
    function CreateTimer(AInterval: integer; AProc: TTimerProc): TFmxHandle;
    procedure DoItemLongTap(AItem: TksVListItem);
    procedure LongTapTimerProc;
    procedure KillTimer(var ATimer: TFmxHandle);
    procedure DoItemClicked(AItem: TksVListItem; ACallClickEvent: Boolean);

    function HandleAppEvent(AAppEvent: TApplicationEvent;
      AContext: TObject): Boolean;
    procedure ResetItemOffsets(AIgnore: TksVListItem);
    procedure SetItemHeight(const Value: integer);
    procedure SetHeaderHeight(const Value: integer);
    procedure SetAppearence(const Value: TksVirtualListViewAppearence);
    procedure SetItemIndex(const Value: integer);
    procedure SetNoItemsText(const Value: TksNoItemsText);
    function GetIsEmpty: Boolean;
    function GetTopItem: TksVListItem;
    //procedure SetFont(const Value: TFont);
  protected
    procedure Paint; override;
    procedure DrawPullToRefresh;
    procedure Resize; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; x, y: single); override;
    procedure MouseMove(Shift: TShiftState; x, y: single); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      x, y: single); override;
    procedure MouseWheel(Shift: TShiftState; WheelDelta: integer;
      var Handled: Boolean); override;
    procedure DoMouseLeave; override;
    procedure DoItemDeleted;
    procedure FocusControl(AItem: TksVListItem; AControl: TControl);
    procedure UnfocusControl;
    procedure DoItemEditInput(Sender: TObject; ARow: TksVListItem; AText: string);
    procedure DoItemDateSelected(Sender: TObject; ARow: TksVListItem; ADate: TDateTime);
    procedure DoItemTimeSelected(Sender: TObject; ARow: TksVListItem; ATime: TDateTime);

    procedure DoBeforeItemPickerSelected(Sender: TObject; ARow: TksVListItem; var AText: string);
    procedure DoItemPickerSelected(Sender: TObject; ARow: TksVListItem; AText: string);
    procedure DoPullRefresh;
    // procedure Tap(const Point:TPointF); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure CreateAniCalc5(AUpdateLimits: Boolean);
    procedure DoCleanupDeletedItems;
    procedure DoItemSwiped(AItem: TksVListItem;
      ASwipeDirection: TksVListSwipeDirection);
    procedure BeginUpdate; override;
    procedure EndUpdate; override;
    procedure ClearItems;
    procedure Invalidate;
    procedure DeselectAll;
    procedure ScrollTo(const Value: integer);
    procedure ScrollToBottom(AAnimated: Boolean);

    procedure UpdateScrollLimmits;
    procedure UncheckAll;
    procedure SwipeItem(AItem: TksVListItem; ASwipeDirection: TksVListSwipeDirection);
    procedure SelectItem(AItem: TksVListItem);
    property Items: TksVListItemList read FItems;
    property ScrollPos: integer read FScrollPos write SetScrollPos;
    property Viewport: TRectF read GetViewport;
    property ItemIndex: integer read FItemIndex write SetItemIndex;
    property IsEmpty: Boolean read GetIsEmpty;
    property TopItem: TksVListItem read GetTopItem;
    property TotalItemHeight: single read FTotalItemHeight;
  published
    property Align;
    property Appearence: TksVirtualListViewAppearence read FAppearence write SetAppearence;
    property CheckBoxes: TksVListCheckBoxOptions read FCheckBoxOptions write SetCheckBoxOptions;
    property DeleteButton: TksVListDeleteButton read FDeleteButton write FDeleteButton;
    //property Font: TFont read FFont write SetFont;
    property Height;

    property ItemHeight: integer read FItemHeight write SetItemHeight default C_VLIST_ITEM_DEFAULT_HEIGHT;
    property HeaderHeight: integer read FHeaderHeight write SetHeaderHeight default C_VLIST_HEADER_DEFAULT_HEIGHT;
    property NoItemsText: TksNoItemsText read FNoItemsText write SetNoItemsText;
    property Opacity;
    property Position;
    property PullToRefresh: TksVListPullToRefreshOptions read FPullToRefresh write FPullToRefresh;
    property SelectionOptions: TksVListSelectionOptions read FSelectionOptions write FSelectionOptions;
    property Size;
    property Width;

    property Ani: TksAniCalc read FAniCalc;

    property CanDeleteItem: TksVListDeletingItemEvent read FCanDeleteItem write FCanDeleteItem;
    property OnItemLongTap: TksVListItemLongTapEvent read FOnItemLongTap write FOnItemLongTap;
    property OnItemClick: TksVListItemClickEvent read FOnItemClick write FOnItemClick;
    property OnItemSwipe: TksVListItemSwipeEvent read FOnItemSwipe write FOnItemSwipe;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnScroll: TNotifyEvent read FOnScroll write FOnScroll;
    property OnPullRefresh: TNotifyEvent read FOnPullRefresh write FOnPullRefresh;
    property OnItemDeleted: TNotifyEvent read FOnItemDeleted write FOnItemDeleted;
    property OnActionButtonClick: TksItemActionButtonClickEvent read FOnActionButtonClick write FOnActionButtonClick;
    property OnItemEditInput: TksItemEditInputEvent read FOnItemEditInputEvent write FOnItemEditInputEvent;
    property OnItemDateSelected: TksItemDateSelectedEvent read FOnItemDateSelectedEvent write FOnItemDateSelectedEvent;
    property OnItemPickerSelected: TksItemSelectPickerItemEvent read FOnItemPickerSelectedEvent write FOnItemPickerSelectedEvent;
    property BeforeItemPickerSelected: TksItemBeforeSelectPickerItemEvent read FBeforeItemPickerSelectedEvent write FBeforeItemPickerSelectedEvent;
    property OnGetPickerItems: TksItemGetPickerItemsEvent read FOnGetPickerItemsEvent write FOnGetPickerItemsEvent;
  end;

  // {$R *.dcr}

procedure Register;

implementation

uses SysUtils, Math, System.Math.Vectors, ksCommon, ksPickers,
  DateUtils, FMX.Forms, FMX.Ani, FMX.Dialogs, System.Threading
  {$IFDEF XE10_OR_NEWER} , FMX.DialogService {$ENDIF}
  ;



procedure Register;
begin
  RegisterComponents('Kernow Software FMX', [TksVirtualListView]);
end;

{ TksVListItem }

function TksVListItem.AddText(x, y: single; AText: string): TksVListItemTextObject;
begin
  Result := AddText(x, y, 0, AText);
end;

function TksVListItem.AddText(x, y, AWidth: single; AText: string): TksVListItemTextObject;
begin
  Result := TksVListItemTextObject.Create(Self);
  Result.FLeft := x;
  Result.FTop := y;
  Result.Width := AWidth;
  Result.Text := AText;
  FObjects.Add(Result);
end;

function TksVListItem.AddImage(x, y, AWidth, AHeight: single; ABitmap: TBitmap): TksVListItemImageObject;
begin
  Result := TksVListItemImageObject.Create(Self);
  Result.FLeft := x;
  Result.FTop := y;
  Result.Width := AWidth;
  Result.Height := AHeight;
  Result.Bitmap := ABitmap;
  FObjects.Add(Result);
end;
  {
procedure TksVListItem.BeginUpdate;
begin
  Inc(FUpdateCount);
end;    }

{
procedure TksVListItem.CacheItem;
begin
  //UpdateStandardObjectPositions;
  //FTitle.CacheTextToBmp(FSelected);
  //FSubTitle.CacheTextToBmp(FSelected);
 // FDetail.CacheTextToBmp(FSelected);

end; }
    {
procedure TksVListItem.ClearCache;
begin
  FTitle.ClearCache;
  FSubTitle.ClearCache;
  FDetail.ClearCache;
end; }

procedure TksVListItem.Changed;
begin
  if FState <> Normal then
    Exit;
  FChanged := True;
  FOwner.Changed(False);
end;

constructor TksVListItem.Create(Owner: TksVListItemList);
begin
  inherited Create; // (nil);
  FActionButtons := TksVListActionButtons.Create(Self);
  FObjects := TksVListObjectList.Create(True);
  FCheckBoxVisible := True;
  FSelectorType := ksSelectorNone;
  FOffset := 0;
  FUpdateCount := 0;
  FAbsoluteIndex := 0;
  FIndex := 0;
  FTagInt := 0;
  FTagStr := '';
  FIconSize := 28;
  FOwner := Owner;
  FChecked := False;
  FState := Normal;
  FCanSelect := True;
  FBackground := claNull;
  FSelectedDate := Now;
  FEditFieldKeyboardType := TVirtualKeyboardType.Alphabet;
  //BeginUpdate;
  try
    FHeight := FOwner.FOwner.FItemHeight;

    FImage := TksVListItemImageObject.Create(Self);
    FImage.Width := 32;
    FImage.Height := 32;
    FImage.VertAlign := TVerticalAlignment.taVerticalCenter;

    FTitle := TksVListItemTextObject.Create(Self);
    FTitle.VertAlign := TVerticalAlignment.taVerticalCenter;

    FSubTitle := TksVListItemTextObject.Create(Self);
    FSubTitle.VertAlign := TVerticalAlignment.taVerticalCenter;
    FSubTitle.TextSettings.FontColor := claDimgray;
    FSubTitle.Font.Size := 14;

    FDetail := TksVListItemTextObject.Create(Self);
    FDetail.VertAlign := TVerticalAlignment.taVerticalCenter;
    FDetail.HorzAlign := TAlignment.taRightJustify;

    FDetail.TextSettings.HorzAlign := TTextAlign.Trailing;
    {$IFDEF IOS}
    FDetail.TextSettings.FontColor := claDodgerblue;
    {$ELSE}
    FDetail.TextSettings.FontColor := claGray;
    {$ENDIF}

    FDetail.Font.Size := 14;


    FAccessory := TksVListItemAccessoryObject.Create(Self);
    FAccessory.VertAlign := TVerticalAlignment.taVerticalCenter;
    FAccessory.HorzAlign := TAlignment.taRightJustify;
  finally
    //EndUpdate;
  end;
  FChanged := True;
end;

function TksVListItem.CreateAniCalc(AOnChange: TNotifyEvent): TAniCalculations;
begin
  Result := TAniCalculations.Create(nil);
  Result.ViewportPositionF := PointF(FOffset, 0);
  Result.Animation := True;
  Result.Averaging := True;
  Result.Interval := 8;
  Result.OnChanged := AOnChange;
end;

procedure TksVListItem.DeleteItem;
var
  Targets: array of TAniCalculations.TTarget;
begin
  FState := Deleting;
  FreeAndNil(FDeleteCalc);
  FDeleteCalc := CreateAniCalc(DeleteCalcChange);
  FDeleteCalc.ViewportPositionF := PointF(0, FHeight);
  SetLength(Targets, 1);
  Targets[0].TargetType := TAniCalculations.TTargetType.Other;
  Targets[0].Point := TPointD.Create(0, 0);
  FDeleteCalc.SetTargets(Targets);
end;

destructor TksVListItem.Destroy;
begin
  FreeAndNil(FSwipeCalc);
  FreeAndNil(FObjects);
  FreeAndNil(FTitle);
  FreeAndNil(FSubTitle);
  FreeAndNil(FDetail);
  FreeAndNil(FImage);
  FreeAndNil(FAccessory);
  FreeAndNil(FActionButtons);
  inherited;
end;

procedure TksVListItem.DoClicked(var AHandled: Boolean);
begin
  if Assigned(FOnClick) then
    FOnClick(Self);
  AHandled := False;
  case FSelectorType of
    ksSelectorEdit: ShowEditInput;
    ksSelectorDate: ShowDatePicker(FSelectedDate);
    ksSelectorTime: ShowTimePicker(FSelectedTime);
    ksSelectorPicker: ShowPicker;
  else
    Exit;
  end;
  AHandled := True;
end;

procedure TksVListItem.DoDatePickerChanged(Sender: TObject; ADate: TDateTime);
begin
  FSelectedDate := ADate;
  FDetail.Text := FormatDateTime('ddd, dd mmm, yyyy', ADate);
  FDetail.ClearCache;
  if Assigned(FOnDateSelected) then
    FOnDateSelected(FOwner.FOwner, Self, ADate);
end;

procedure TksVListItem.DoTimePickerChanged(Sender: TObject; ATime: TDateTime);
begin
  FSelectedTime := ATime;
  FDetail.Text := FormatDateTime('hh:nn', ATime);
  FDetail.ClearCache;
  if Assigned(FOnTimeSelected) then
    FOnTimeSelected(FOwner.FOwner, Self, ATime);
end;

procedure TksVListItem.DoItemPickerChanged(Sender: TObject;
  AItem: string; AValueIndex: Integer);
var
  ATask: ITask;
begin
  if Assigned(FBeforeSelectPickerItem) then
    FBeforeSelectPickerItem(FOwner.FOwner, Self, AItem);

  FSelectedItem := AItem;
  FDetail.Text := AItem;
  FDetail.ClearCache;

  ATask := TTask.Create (procedure ()
   begin
     TThread.Synchronize(nil,procedure
                  begin
                     //Interact with UI
                    if Assigned(FOnSelectPickerItem) then
                      FOnSelectPickerItem(FOwner.FOwner, Self, AItem);
                  end);
   end);
 ATask.Start;
end;

procedure TksVListItem.SelectItem(ADeselectAfter: integer);
var
  AStart: TDateTime;
begin
  if (FPurpose <> None) or (FCanSelect = False) then
    Exit;

  FOwner.FOwner.ItemIndex := FIndex;

  Application.ProcessMessages;

  if ADeselectAfter > 0 then
  begin
    AStart := Now;
    while MilliSecondsBetween(AStart, Now) < ADeselectAfter do
      Sleep(10);
    Selected := False;
  end;
end;

procedure TksVListItem.SetAccessory(const Value: TksVListItemAccessoryObject);
begin
  FAccessory.Assign(Value);
  Changed;
end;

procedure TksVListItem.SetBackground(const Value: TAlphaColor);
begin
  if FBackground <> Value then
  begin
    FBackground := Value;
    Changed;
  end;
end;

procedure TksVListItem.SetCanSelect(const Value: Boolean);
begin
  if FCanSelect <> Value then
  begin
    FCanSelect := Value;
    Changed;
  end;
end;

procedure TksVListItem.SetChecked(const Value: Boolean);
begin
  if FChecked <> Value then
  begin
    FChecked := Value;
    Changed;
  end;
end;

procedure TksVListItem.SetDetail(const Value: TksVListItemTextObject);
begin
  FDetail.Assign(Value);
  Changed;
end;

procedure TksVListItem.SetHeight(const Value: integer);
begin
  if FHeight <> Value then
  begin
    FHeight := Value;
    Changed;
    if (FHeight = 0) and (FState = Deleting) then
      FState := Deleted;

  end;
end;

procedure TksVListItem.SetIconSize(const Value: integer);
begin
  if FIconSize <> Value then
  begin
    FIconSize := Value;
    Changed;
  end;
end;

procedure TksVListItem.SetImage(const Value: TksVListItemImageObject);
begin
  FImage.Assign(Value);
  Changed;
end;

procedure TksVListItem.SetOffset(const Value: integer);
begin
  if FOffset <> Value then
  begin
    FOffset := Value;
    if (FOffset = FActionButtons.TotalWidth) or (FOffset = 0) then
      FState := Normal;

  end;
end;

procedure TksVListItem.SetPurpose(const Value: TksVListItemPurpose);
begin
  if FPurpose <> Value then
  begin
    FPurpose := Value;
    if FPurpose = Header then
      FHeight := FOwner.FOwner.HeaderHeight
    else
      FHeight := FOwner.FOwner.ItemHeight;
    Changed;
  end;
end;

procedure TksVListItem.SetSelected(const Value: Boolean);
begin
  if FSelected <> Value then
  begin
    if FCanSelect = False then
      FSelected := False
    else
      FSelected := Value;
    FObjects.ClearCache;
    FTitle.ClearCache;
    FSubTitle.ClearCache;
    FDetail.ClearCache;
    FAccessory.ClearCache;
    //ClearCache;
    //CacheItem;
    Changed;
  end;
end;

procedure TksVListItem.SetSubTitle(const Value: TksVListItemTextObject);
begin
  FSubTitle.Assign(Value);
  Changed;
end;

procedure TksVListItem.SetTitle(const Value: TksVListItemTextObject);
begin
  FTitle.Assign(Value);
  Changed;
end;

procedure TksVListItem.ShowEditInput;
{$IFDEF XE10_OR_NEWER}
var
  ATask: ITask;
  AStr: string;
{$ENDIF}
begin
  PickerService.HidePickers;
  {$IFDEF XE10_OR_NEWER}
  TDialogService.InputQuery(FTitle.Text, [''], [FDetail.Text],
  procedure(const AResult: TModalResult; const AValues: array of string)
  begin
    if AResult = mrOk then
    begin
      FDetail.Text := AValues[0];
      AStr := AValues[0];
      FDetail.ClearCache;
      Changed;

      ATask := TTask.Create (procedure ()
     // var
     //   AStr: string;
      begin
       // AStr := AValues[0];
        TThread.Synchronize(nil,procedure
                     begin
                        //Interact with UI

                       if Assigned(FOnEditInput) then
                        FOnEditInput(Self, Self, AStr);

                     end);
      end);
     ATask.Start;

    {  if Assigned(FOnEditInput) then
        FOnEditInput(Self, Self, AValues[0]);
      FDetail.ClearCache;         }
    end;
  end);
  {$ENDIF}
end;

procedure TksVListItem.ShowPicker;
var
  AItems: TStrings;
  ASelected: string;
  AIndex: integer;
begin
  PickerService.HidePickers;
  AItems := TStringList.Create;
  try
    ASelected := '';
    if Assigned(FOwner.FOwner.OnGetPickerItems) then
      FOwner.FOwner.OnGetPickerItems(FOwner.FOwner, Self, ASelected, AItems);

    if ASelected = '' then
      ASelected := FDetail.Text;
    if AItems.IndexOf(ASelected) > -1 then
      AIndex := AItems.IndexOf(ASelected)
    else
      AIndex := 0;
    PickerService.ShowItemPicker(AItems, '',  AIndex, DoItemPickerChanged);
  finally
    FreeAndNil(AItems);
  end;
end;

procedure TksVListItem.ShowDatePicker(ASelected: TDateTime);
begin
  PickerService.HidePickers;
  PickerService.ShowDatePicker('', ASelected, DoDatePickerChanged);
end;

procedure TksVListItem.ShowTimePicker(ASelected: TDateTime);
begin
  PickerService.HidePickers;
  PickerService.ShowTimePicker('', ASelected, DoTimePickerChanged);
end;

procedure TksVListItem.SlideOut(ADirection: TksVListSwipeDirection);
var
  Targets: array of TAniCalculations.TTarget;

begin
  FState := Sliding;
  FSelected := False;
  FreeAndNil(FSwipeCalc);
  FSwipeCalc := CreateAniCalc(SwipeCalcChange);
  SetLength(Targets, 1);
  Targets[0].TargetType := TAniCalculations.TTargetType.Other;
  if ADirection = ksSwipeFromLeft then
    Targets[0].Point := TPointD.Create(Min(FOffset + FActionButtons.TotalWidth,
      FActionButtons.TotalWidth), 0)
  else
    Targets[0].Point := TPointD.Create(Max(FOffset - FActionButtons.TotalWidth,
      0 - FActionButtons.TotalWidth), 0);
  FSwipeCalc.SetTargets(Targets);
end;

procedure TksVListItem.SlideIn;
var
  Targets: array of TAniCalculations.TTarget;
begin
  FState := Sliding;
  FreeAndNil(FSwipeCalc);
  FSwipeCalc := CreateAniCalc(SwipeCalcChange);
  SetLength(Targets, 1);
  Targets[0].TargetType := TAniCalculations.TTargetType.Other;
  Targets[0].Point := TPointD.Create(0, 0);
  FSwipeCalc.SetTargets(Targets);
end;

procedure TksVListItem.SwipeCalcChange(Sender: TObject);
begin
  Offset := Round(FSwipeCalc.ViewportPosition.x);
  FOwner.FOwner.Invalidate;
end;

procedure TksVListItem.DeleteCalcChange(Sender: TObject);
begin
  if FOwner <> nil then
  begin
    Height := Round(FDeleteCalc.ViewportPosition.y);
    FOwner.UpdateItemRects;
    FOwner.FOwner.Invalidate;
  end;
end;

procedure TksVListItem.UpdateStandardObjectPositions;
begin
  Inc(FUpdateCount);
  try
    FTitle.FLeft := 0;
    FTitle.FTop := 0;
    FTitle.FVertAlign := TVerticalAlignment.taVerticalCenter;

    if (FSubTitle.Visible) and (FSubTitle.Text <> '') then
    begin
      FTitle.FTop := (0 - (16 / 2)) - GetScreenScale;
      FSubTitle.FLeft := 0;
      FSubTitle.FTop := 0;
      if FTitle.Visible then
        FSubTitle.FTop := ((16 / 2)) + GetScreenScale;
      FSubTitle.FVertAlign := TVerticalAlignment.taVerticalCenter;

    end;

    FDetail.FLeft := 0;
    FDetail.FTop := 0;
    FDetail.FVertAlign := TVerticalAlignment.taVerticalCenter;

    FAccessory.FLeft := 0;
    FAccessory.FTop := 0;
    FAccessory.FVertAlign := TVerticalAlignment.taVerticalCenter;

    if FPurpose = Header then
    begin
      FTitle.VertAlign := TVerticalAlignment.taAlignBottom;
      FTitle.Top := -6;
    end;
  finally
    Dec(FUpdateCount);
  end;
end;

function TksVListItem.AddChatBubble(AText, ASender: string; ALeftAlign: Boolean): TksVListItemBubbleObject;
begin
  Result := TksVListItemBubbleObject.Create(Self);
  Result.FLeft := 6;
  Result.FTop := 12;
  Result.TextSettings.WordWrap := True;
  Result.MaxWidth := Round(FOwner.FOwner.Width * 0.6);
  Result.Width := 0;
  Result.TextSettings.Trimming := TTextTrimming.None;
  Result.Text := AText;
  Result.Sender := ASender;
  Result.VertAlign := TVerticalAlignment.taAlignTop;
  if not ALeftAlign then
  begin
    Result.HorzAlign := TAlignment.taRightJustify;
  end;

  FObjects.Add(Result);
  Height := Round(Result.CalculateSize.Height)+40;
end;

function TksVListItem.DrawRect(x, y, AWidth, AHeight, ACornerRadius: single; AStroke, AFill: TAlphaColor): TksVListItemShapeObject;
begin
  Result := TksVListItemShapeObject.Create(Self);
  Result.FLeft := x;
  Result.FTop := y;
  Result.Width := AWidth;
  Result.Height := AHeight;
  Result.CornerRadius := ACornerRadius;
  Result.FStroke.Color := AStroke;
  Result.FFill.Color := AFill;
  FObjects.Add(Result);
end;

procedure TksVListItem.DrawToCanvas(ACanvas: TCanvas; AScrollPos: single;
  ADrawToCache: Boolean);

  function GetCheckBoxImage(AChecked: Boolean): TksAccessoryType;
  begin
    Result := TksAccessoryType.atCheckBox;
    if AChecked then
      Result := TksAccessoryType.atCheckBoxChecked;
  end;

var
//  AState: TCanvasSaveState;
  ARect: TRectF;
  AInternalRect: TRectF;
  ACheckBoxRect: TRectF;
  ACheckBoxes: TksVListCheckBoxOptions;
  //ASeperatorStart: single;
  r: TRectF;
  AButtonRect: TRectF;
  ICount: integer;
  AScrollOffset: single;
//  AIntersect: TRectF;
begin
  if FChanged then
  begin
    UpdateStandardObjectPositions;
    FChanged := False;
  end;

  ARect := FItemRect;

  AScrollOffset := 0 - AScrollPos;

  OffsetRect(ARect, FOffset, AScrollOffset);
  if Purpose = TksVListItemPurpose.Header then
  begin
    if ARect.Top < 0 then
      OffsetRect(ARect, 0, 0-ARect.Top);
  end;
  r := ARect;

  if ADrawToCache then
    OffsetRect(ARect, 0 - ARect.Left, 0 - ARect.Top);

  AInternalRect := ARect;
  AInternalRect.Left := AInternalRect.Left + 8;
  AInternalRect.Right := (AInternalRect.Right - Round(C_VLIST_SCROLLBAR_WIDTH / GetScreenScale));

  ACanvas.Stroke.Kind := TBrushKind.Solid;
  ACanvas.Fill.Kind := TBrushKind.Solid;

  if FOffset <> 0 then
  begin
    AButtonRect := FItemRect;
    OffsetRect(AButtonRect, 0, 0 - AScrollPos);
    if FOffset < 0 then
      AButtonRect.Left := AButtonRect.Right + FOffset
    else
      AButtonRect.Right := AButtonRect.Left + FOffset;
    FActionButtons.DrawToCanvas(ACanvas, AButtonRect);
  end;

  //AState := ACanvas.SaveState;
  try
    {AIntersect := r;
    if AIntersect.Top < 0 then AIntersect.Top := 0;
    if AIntersect.Bottom > Height then AIntersect.Bottom := Height;


    }
   // ACanvas.IntersectClipRect(r);
    ACanvas.Fill.Color := GetColorOrDefault(FOwner.FOwner.Appearence.Background, claWhite);

    if FPurpose = TksVListItemPurpose.Header then
      ACanvas.Fill.Color := GetColorOrDefault(FOwner.FOwner.Appearence.HeaderColor, $FFEAEAEA);

    if FBackground <> claNull then
      ACanvas.Fill.Color := FBackground;


    if (FSelected) and (FOwner.FOwner.Appearence.SelectedColor <> claNull) then
    begin
      ACanvas.Fill.Color := FOwner.FOwner.Appearence.SelectedColor;
    end;

    ACanvas.Stroke.Color :=  ACanvas.Fill.Color;//FOwner.FOwner.Appearence.SelectedColor;
ACanvas.FillRect(ARect, 0, 0, AllCorners, 1);

    ACanvas.DrawRect(ARect, 0, 0, AllCorners, 1);

    if (FPurpose = TksVListItemPurpose.None) and (FCheckBoxVisible) then
    begin
      ACheckBoxes := FOwner.FOwner.FCheckBoxOptions;
      if ACheckBoxes.Visible then
      begin
        ACheckBoxRect := AInternalRect;
        if ACheckBoxes.Alignment = ksCbLeftAlign then
        begin
          ACheckBoxRect.Right := ACheckBoxRect.Left + 28;
          AInternalRect.Left := AInternalRect.Left + 28;
        end
        else
        begin
          ACheckBoxRect.Left := ACheckBoxRect.Right - 28;
          AInternalRect.Right := AInternalRect.Right - 28;
        end;

        AAccessories.DrawAccessory(ACanvas, ACheckBoxRect, GetCheckBoxImage(FChecked), claDimgray, claNull);
      end;
    end;

    AInternalRect.Left := AInternalRect.Left + 4;
    AInternalRect.Right := AInternalRect.Right - 4;

    if FImage.IsEmpty = False then
    begin
      FImage.DrawToCanvas(ACanvas, AInternalRect);
      AInternalRect.Left := AInternalRect.Left + FImage.Width + 8;
    end;

    if (FAccessory.Visible) and (FPurpose = TksVListItemPurpose.None) then
    begin
      //AInternalRect.Right := AInternalRect.Right + (Accessory.Width/2);
      Accessory.DrawToCanvas(ACanvas, AInternalRect);
      //AInternalRect.Right := AInternalRect.Right - (Accessory.Width/2);
      if FAccessory <> nil then
        AInternalRect.Right := (AInternalRect.Right - (FAccessory.Width+(2*GetScreenScale(False))));
    end;


    Title.DrawToCanvas(ACanvas, AInternalRect);
    SubTitle.DrawToCanvas(ACanvas, AInternalRect);
    FDetail.DrawToCanvas(ACanvas, AInternalRect);

    for ICount := 0 to FObjects.Count-1 do
      FObjects[ICount].DrawToCanvas(ACanvas, AInternalRect);

  finally
  //  ACanvas.RestoreState(AState);
  end;

  ACanvas.Stroke.Thickness := 1 / GetScreenScale;
  ACanvas.Stroke.Color := FOwner.FOwner.Appearence.SeparatorColor;
  if ACanvas.Stroke.Color = claNull then
    ACanvas.Stroke.Color := claDarkgray;

  if (FIndex = 0) {and (FPurpose = None) and (AScrollPos < 0)} then
    ACanvas.DrawLine(PointF(0, ARect.Top+(ACanvas.Stroke.Thickness/2)), PointF(ARect.Width, ARect.Top+(ACanvas.Stroke.Thickness/2)), 1);

  ACanvas.DrawLine(PointF(0, ARect.Bottom-(ACanvas.Stroke.Thickness/2)), PointF(ARect.Width, ARect.Bottom-(ACanvas.Stroke.Thickness/2)), 1);
end;

{
procedure TksVListItem.EndUpdate;
begin
  if FUpdateCount > 0 then
  begin
    Dec(FUpdateCount);
    if FUpdateCount = 0 then
      Changed;
  end;
end;  }

function TksVListItem.IsItemVisible(AViewPort: TRectF): Boolean;
var
  r: TRectF;
begin
  Result := IntersectRectF(r, FItemRect, AViewPort);
end;

{procedure TksVListItem.OnEditChange(Sender: TObject);
begin
  FDetail.Text := (Sender as TEdit).Text;
  //ClearCache;
end; }

{ TksVirtualListView }
    {
procedure TksVirtualListView.CacheItems(AStartIndex, AEndIndex: integer);
var
  ICount: integer;
begin
  for ICount := AStartIndex to AEndIndex do
    Items[ICount].CacheItem;
end;  }

procedure TksVirtualListView.ClearItems;
begin
  FItems.Clear;
end;

function TksVirtualListView.HandleAppEvent(AAppEvent: TApplicationEvent;
  AContext: TObject): Boolean;
begin
  case AAppEvent of
    TApplicationEvent.LowMemory:
      ;
  end;
  Result := True;
end;

constructor TksVirtualListView.Create(AOwner: TComponent);
begin
  inherited;
  TPlatformServices.Current.SupportsPlatformService(IFMXTimerService,
    FTimerService);
  if TPlatformServices.Current.SupportsPlatformService
    (IFMXApplicationEventService, IInterface(FEventService)) then
    FEventService.SetApplicationEventHandler(HandleAppEvent);

  FAppearence := TksVirtualListViewAppearence.Create(Self);
  FNoItemsText := TksNoItemsText.Create(Self);
  //FFont := TFont.Create;
  FDeletedItemCleanup := CreateTimer(500, DoCleanupDeletedItems);

  FItemIndex := -1;
  FScrollPos := 0;
  FUpdateCount := 0;
  FItemHeight := C_VLIST_ITEM_DEFAULT_HEIGHT;
  FHeaderHeight := C_VLIST_HEADER_DEFAULT_HEIGHT;
  FCheckBoxOptions := TksVListCheckBoxOptions.Create(Self);
  FSelectionOptions := TksVListSelectionOptions.Create(Self);
  FItems := TksVListItemList.Create(Self);
  FScrollBar := TksScrollBar.Create(Self);
  FScrollBar.Stored := False;

  FPullToRefresh := TksVListPullToRefreshOptions.Create;
  FDeleteButton := TksVListDeleteButton.Create;

  FScrollBar.Width := 8;
  FPendingRefresh := False;

  CreateAniCalc5(False);

  FScrollBar.Orientation := TOrientation.Vertical;
  // FScrollBar.Align := TAlignLayout.Right;
  FScrollBar.OnChange := ScrollBarChanged;
  AddObject(FScrollBar);

  HitTest := True;
  FRefreshing := False;
  if (csDesigning in ComponentState) then
  begin
    Items.Add('Title 1', 'sub title', 'detail');
    Items.Add('Title 2', 'sub title', 'detail');
    Items.Add('Title 3', 'sub title', 'detail');
  end;
end;

procedure TksVirtualListView.CreateAniCalc5(AUpdateLimits: Boolean);
begin
  FreeAndNil(FAniCalc);
  FAniCalc := TksAniCalc.Create(nil);
  FAniCalc.OnChanged := AniCalcChange;
  //FAniCalc.ViewportPositionF := PointF(0, 0);
  FAniCalc.ViewportPositionF := PointF(0, FScrollPos);
  FAniCalc.UpdatePosImmediately;
  FAniCalc.Animation := True;
  FAniCalc.Averaging := True;
  FAniCalc.Interval := 8;
  FAniCalc.BoundsAnimation := True;
  FAniCalc.TouchTracking := [ttVertical];
  FAniCalc.OnChanged := AniCalcChange;
  FAniCalc.OnStart := AniCalcStart;
  FAniCalc.OnStop := AniCalcStop;
  if AUpdateLimits then
    UpdateScrollLimmits;
end;

destructor TksVirtualListView.Destroy;
begin
  KillTimer(FDeletedItemCleanup);
  FreeAndNil(FAniCalc);
  FreeAndNil(FItems);
  FreeAndNil(FCheckBoxOptions);
  FreeAndNil(FSelectionOptions);
  //FreeAndNil(/FFont);
  // FreeAndNil(FActionButtons);
  FreeAndNil(FPullToRefresh);
  FreeAndNil(FDeleteButton);
{$IFDEF NEXTGEN}
  FScrollBar.DisposeOf;
{$ELSE}
  FScrollBar.Free;
{$ENDIF}
  FreeAndNil(FNoItemsText);
  FreeAndNil(FAppearence);
  inherited;
end;

procedure TksVirtualListView.DoCleanupDeletedItems;
var
  ICount: integer;
begin
  for ICount := Items.Count - 1 downto 0 do
  begin
    if Items[ICount].State = Deleted then
      Items.Delete(ICount, False);
  end;
end;

procedure TksVirtualListView.DoItemClicked(AItem: TksVListItem;
  ACallClickEvent: Boolean);
var
  AHandled: Boolean;
begin
  if AItem = nil then
    Exit;

  if AItem.Purpose = TksVListItemPurpose.Header then
    Exit;

  if FCheckBoxOptions.Visible then
  begin
    if FCheckBoxOptions.FMode = ksSingleSelect then
      UncheckAll;
    AItem.FChecked := not AItem.Checked;
  end;

  SelectItem(AItem);
  Invalidate;

  //Application.ProcessMessages;

  //FMouseDownItem := nil;
  AItem.DoClicked(AHandled);

  if AHandled = False then
  begin
    if Assigned(FOnItemClick) then
      FOnItemClick(Self, AItem);
  end;
end;

procedure TksVirtualListView.DoItemDateSelected(Sender: TObject;
  ARow: TksVListItem; ADate: TDateTime);
begin
  if Assigned(FOnItemDateSelectedEvent) then
    FOnItemDateSelectedEvent(Self, ARow, ADate);
  {$IFDEF ANDROID}
  Application.ProcessMessages;
  Repaint;
  {$ENDIF}
end;

procedure TksVirtualListView.DoItemDeleted;
begin
  if Assigned(FOnItemDeleted) then
    FOnItemDeleted(Self);
end;

procedure TksVirtualListView.DoItemEditInput(Sender: TObject;
  ARow: TksVListItem; AText: string);
begin
  if Assigned(FOnItemEditInputEvent) then
    FOnItemEditInputEvent(Self, ARow, AText);
end;

procedure TksVirtualListView.DoItemSwiped(AItem: TksVListItem;
  ASwipeDirection: TksVListSwipeDirection);
var
  ADeleteIcon: TksAccessoryType;
  ADeleteBtn: TksVListActionButton;
begin
  if AItem.Purpose <> None then
    Exit;

  if AItem.FOffset <> 0 then
  begin
    AItem.SlideIn;
    Exit;
  end;

  FAniCalc.UpdatePosImmediately;
  AItem.FActionButtons.Clear;
  if Assigned(FOnItemSwipe) then
    FOnItemSwipe(Self, AItem, ASwipeDirection, AItem.FActionButtons);
  if ASwipeDirection = ksSwipeFromRight then
  begin
    if FDeleteButton.Enabled then
    begin
      ADeleteIcon := atNone;
      if FDeleteButton.ShowImage then
        ADeleteIcon := atTrash;
      ADeleteBtn := AItem.FActionButtons.AddButton(FDeleteButton.FText,
        FDeleteButton.Color, FDeleteButton.TextColor, ADeleteIcon, FDeleteButton.Width);
      ADeleteBtn.IsDeleteButton := True;

    end;
  end;
  if AItem.FActionButtons.Count = 0 then
    Exit;
  AItem.SlideOut(ASwipeDirection);
end;

procedure TksVirtualListView.DoItemTimeSelected(Sender: TObject;
  ARow: TksVListItem; ATime: TDateTime);
begin
  if Assigned(FOnItemTimeSelectedEvent) then
    FOnItemTimeSelectedEvent(Self, ARow, ATime);
  {$IFDEF ANDROID}
  Application.ProcessMessages;
  Repaint;
  {$ENDIF}
end;

procedure TksVirtualListView.DoMouseLeave;
begin
  if (FAniCalc <> nil) then
    FAniCalc.MouseLeave;
  inherited DoMouseLeave;
end;

procedure TksVirtualListView.DoPullRefresh;
begin
  KillTimer(FPullRefreshTimer);
  if Assigned(FOnPullRefresh) then
    FOnPullRefresh(Self);

end;

procedure TksVirtualListView.DrawPullToRefresh;
var
  ARefreshArea: TRectF;
  AText: string;
  AState: TCanvasSaveState;
begin
  if (ScrollPos < 0) and (FPullToRefresh.Enabled) then
  begin
    Canvas.Stroke.Color := claGainsboro;
    Canvas.Stroke.Kind := TBrushKind.Solid;
    Canvas.DrawLine(PointF(0, 0 - FScrollPos), PointF(Width, 0 - FScrollPos), 1);

    ARefreshArea := RectF(0, 0, Width, 0 - ScrollPos);
    AState := Canvas.SaveState;
    try
      Canvas.IntersectClipRect(ARefreshArea);
      Canvas.Fill.Color := claDimgray;
      Canvas.Font.Size := 14;
      Canvas.Fill.Kind := TBrushKind.Solid;

      AText := FPullToRefresh.PullText;
      if FPendingRefresh then
        AText := FPullToRefresh.ReleaseText;

      Canvas.FillText(RectF(0, 0, Width, 50), AText, False, 1, [],
        TTextAlign.Center, TTextAlign.Center);
    finally
      Canvas.RestoreState(AState);
    end;
  end;
end;

procedure TksVirtualListView.DoItemLongTap(AItem: TksVListItem);
begin
  if Assigned(FOnItemLongTap) then
    FOnItemLongTap(Self, AItem);
end;



procedure TksVirtualListView.DoBeforeItemPickerSelected(Sender: TObject;
  ARow: TksVListItem; var AText: string);
begin
  if Assigned(FBeforeItemPickerSelectedEvent) then
    FBeforeItemPickerSelectedEvent(Self, ARow, AText);
end;


procedure TksVirtualListView.DoItemPickerSelected(Sender: TObject;
  ARow: TksVListItem; AText: string);
begin
  if Assigned(FOnItemPickerSelectedEvent) then
    FOnItemPickerSelectedEvent(Self, ARow, AText);
end;

procedure TksVirtualListView.LongTapTimerProc;
var
  AItem: TksVListItem;
begin
  if FLongTapTimer = 0 then
    Exit;
  KillTimer(FLongTapTimer);

  if (FAniCalc.Down) then
  begin
    if (FMousePt.y > FMouseDownPos.y - 4) and (FMousePt.y < FMouseDownPos.y + 4)
    then
    begin
      AItem := FItems.ItemAtPos(FMousePt.x, FMousePt.y);
      DoItemClicked(AItem, False);
      //FAniCalc.MouseLeave;
    end;
  end;
end;

procedure TksVirtualListView.DeselectAll;
var
  ICount: integer;
begin
  for ICount := 0 to Items.Count - 1 do
    Items[ICount].Selected := False;
end;

procedure TksVirtualListView.EndUpdate;
begin
  if FUpdateCount > 0 then
  begin
    if FUpdateCount = 1 then
    begin
      FItems.UpdateItemRects;
      //FAniCalc.UpdatePosImmediately;
      UpdateScrollLimmits;
      //CacheItems(0, Min(C_VLIST_CACHE_COUNT - 1, FItems.Count - 1));

      Invalidate;
    end;
  end;
  Dec(FUpdateCount);
  inherited EndUpdate;
end;

procedure TksVirtualListView.FocusControl(AItem: TksVListItem; AControl: TControl);
begin
  if FFocusedControl = AControl then
    Exit;
  UnfocusControl;
  FFocusedControl := AControl;
  AControl.Width := 150;
  AControl.Position.X := (Width - AControl.Width) - 30;
  AControl.Position.Y := (((AItem.ItemRect.Top + AItem.ItemRect.Bottom) - AControl.Height) / 2) - ScrollPos;
  AddObject(AControl);
  AControl.SetFocus;
  TEdit(AControl).SelStart := Length(TEdit(AControl).Text);
end;

function TksVirtualListView.GetIsEmpty: Boolean;
begin
  Result := FItems.Count = 0;
end;

function TksVirtualListView.GetTopItem: TksVListItem;
begin
  Result := nil;
  if FItems.Count > 0 then
    Result := FItems.Items[0];
end;

function TksVirtualListView.GetViewport: TRectF;
begin
  Result := RectF(0, 0, Width, Height);
  OffsetRect(Result, 0, FScrollPos);
end;

procedure TksVirtualListView.Invalidate;
begin
  InvalidateRect(ClipRect);
end;

procedure TksVirtualListView.AniCalcStart(Sender: TObject);
begin
  if Scene <> nil then
    Scene.ChangeScrollingState(Self, True);
end;

procedure TksVirtualListView.AniCalcChange(Sender: TObject);
begin
  ScrollPos := Round(FAniCalc.ViewportPosition.y);
end;

procedure TksVirtualListView.AniCalcStop(Sender: TObject);
begin
  TAnimator.AnimateFloat(FScrollBar, 'Opacity', 0);
  if Scene <> nil then
    Scene.ChangeScrollingState(nil, False);
end;

procedure TksVirtualListView.BeginUpdate;
begin
  inherited;
  Inc(FUpdateCount);
end;

procedure TksVirtualListView.Paint;
var
  ICount: integer;
  AState: TCanvasSaveState;
  AItem: TksVListItem;
  AViewPort: TRectF;
  //ARefreshArea: TRectF;
  //ARefreshLabel: string;
  ATopItem: integer;
  //ARect: TRectF;
  //r: TRectF;
begin
  if FUpdateCount > 0 then
    Exit;

  AViewPort := Viewport;

  if (csDesigning in ComponentState) then
    DrawDesignBorder(claDimgray, claDimgray);


  AState := Canvas.SaveState;
  try
    Canvas.IntersectClipRect(ClipRect);
    if FAppearence.Background <> claNull then
      Canvas.Clear(FAppearence.Background);

    if FItems.Count = 0 then
      FNoItemsText.DrawToCanvas(Canvas, ClipRect);

    if FUpdateCount > 0 then
      Exit;

    DrawPullToRefresh;

    ATopItem := -1;

    for ICount := Items.Count - 1 downto 0 do
      if Items[ICount].FState = Deleted then
        Items.Delete(ICount, False);

    for ICount := 0 to Items.Count - 1 do
    begin
      AItem := Items[ICount];
      if (AItem.IsItemVisible(AViewPort)) and (AItem.Purpose = TksVListItemPurpose.None) then
      begin
        if ATopItem = -1 then
          ATopItem := ICount;
        AItem.DrawToCanvas(Canvas, Trunc(FScrollPos), False);
      end;
      //else if ATopItem > -1 then
      //  Break;
    end;

    // draw the headers...
    for ICount := 0 to Items.Count - 1 do
    begin
      AItem := Items[ICount];
      if {(AItem.IsItemVisible(AViewPort)) and} (AItem.Purpose = TksVListItemPurpose.Header) then
      begin

        AItem.DrawToCanvas(Canvas, Trunc(FScrollPos), False);
      end
    end;

  finally
    Canvas.RestoreState(AState);
  end;
end;

procedure TksVirtualListView.ResetItemOffsets(AIgnore: TksVListItem);
var
  ICount: integer;
begin
  for ICount := FItems.Count - 1 downto 0 do
  begin
    if FItems[ICount].FOffset <> 0 then
    begin
      if FItems[ICount] <> AIgnore then
      begin
        FItems[ICount].SlideIn;
        //FAniCalc.MouseLeave;
      end;
    end;
  end;
end;

procedure TksVirtualListView.Resize;
begin
  inherited;
  FItems.UpdateItemRects;
  UpdateScrollLimmits;
  InvalidateRect(ClipRect);
end;

procedure TksVirtualListView.ScrollBarChanged(Sender: TObject);
begin
{$IFDEF MSWINDOWS}
  ScrollPos := Round(FScrollBar.Value);
  FAniCalc.ViewportPositionF := PointF(0, FScrollPos);
  FAniCalc.UpdatePosImmediately;
{$ENDIF}
end;

procedure TksVirtualListView.ScrollTo(const Value: integer);
var
  ANewValue: integer;
begin
  ANewValue := Value;
  if ANewValue < 0 then
    ANewValue := 0;
  if ANewValue > FMaxScrollPos then
    ANewValue := FMaxScrollPos;
  if ((ANewValue - Height) < FMaxScrollPos) and (ANewValue >= 0) then
  begin
    // FScrollPos := ANewValue;
    ScrollPos := ANewValue;
    UpdateScrollLimmits;
    Invalidate;
  end;
end;

procedure TksVirtualListView.ScrollToBottom(AAnimated: Boolean);
begin
 Application.ProcessMessages;
  if AAnimated then
    TAnimator.AnimateIntWait(Self, 'ScrollPos', FMaxScrollPos)
  else
    ScrollPos := FMaxScrollPos;
  //Application.ProcessMessages;
  FAniCalc.ViewportPositionF := PointF(0, FMaxScrollPos);
 FAniCalc.UpdatePosImmediately;
 Application.ProcessMessages;
end;

procedure TksVirtualListView.SelectItem(AItem: TksVListItem);
begin
  if FSelectionOptions.SelectionType = ksSingleSelect then
  begin
    //DeselectAll;
    if FAniCalc.Down then
      AItem.SelectItem(0)
    else
    begin
      case (FSelectionOptions.KeepSelection) of
        True: AItem.SelectItem(0);
        False: AItem.SelectItem(100);
      end;
    end
  end
  else
  begin
    AItem.Selected := not AItem.Selected;
  end;
end;

procedure TksVirtualListView.SetAppearence(const Value: TksVirtualListViewAppearence);
begin
  FAppearence.Assign(Value);
end;

procedure TksVirtualListView.SetCheckBoxOptions(const Value
  : TksVListCheckBoxOptions);
begin
  FCheckBoxOptions := Value;
end;
    {
procedure TksVirtualListView.SetFont(const Value: TFont);
begin
   FFont.Assign(Value);
end;}

procedure TksVirtualListView.SetHeaderHeight(const Value: integer);
var
  ICount: integer;
begin
  if FHeaderHeight <> Value then
  begin
    FHeaderHeight := Value;
    for ICount := 0 to Items.Count - 1 do
      if Items[ICount].Purpose = TksVListItemPurpose.Header then
        Items[ICount].FHeight := Value;
    Items.UpdateItemRects;
    Invalidate;
  end;
end;

procedure TksVirtualListView.SetItemHeight(const Value: integer);
var
  ICount: integer;
begin
  if FItemHeight <> Value then
  begin
    FItemHeight := Value;
    for ICount := 0 to Items.Count - 1 do
      if Items[ICount].Purpose = TksVListItemPurpose.None then
      Items[ICount].FHeight := Value;
    Items.UpdateItemRects;
    Invalidate;
  end;
end;

procedure TksVirtualListView.SetItemIndex(const Value: integer);
var
  ICount: integer;
begin
  FItemIndex := Value;
  for ICount := 0 to FItems.Count-1 do
    Items[ICount].Selected := ICount = FItemIndex;
  Invalidate;
end;

procedure TksVirtualListView.SetNoItemsText(const Value: TksNoItemsText);
begin
  FNoItemsText.Assign(Value);
end;

procedure TksVirtualListView.SetScrollPos(const Value: integer);
begin
  if not SameValue(FScrollPos, Value, TEpsilon.Vector) then
  begin
    UnfocusControl;
    PickerService.HidePickers;//HidePickers(False);

    FItems.UpdateItemRects;
    FScrollBar.Visible := True;
    FScrollBar.Opacity := 1;
    FScrollPos := Value;

    //FItems.UpdateItemHeaders;
    InvalidateRect(ClipRect);
    if Assigned(FOnScroll) then
      FOnScroll(Self);
    FScrollBar.OnChange := nil;
    FScrollBar.Value := Value;
    FScrollBar.OnChange := ScrollBarChanged;

    if (value = 0) and (FPendingRefresh) then
    begin
      FAniCalc.UpdatePosImmediately;
      Application.ProcessMessages;
      if Assigned(FOnPullRefresh) then
        FOnPullRefresh(Self);
    end;
  end;
end;

procedure TksVirtualListView.SwipeItem(AItem: TksVListItem;
  ASwipeDirection: TksVListSwipeDirection);
begin
  DoItemSwiped(AItem, ASwipeDirection);
end;

procedure TksVirtualListView.UncheckAll;
var
  ICount: integer;
begin
  for ICount := 0 to Items.Count - 1 do
    Items[ICount].FChecked := False;
end;

procedure TksVirtualListView.UnfocusControl;
begin
  if FFocusedControl <> nil then
  begin
    FFocusedControl.Root.SetFocused(nil);
    //FFocusedControl.Visible := False;
    RemoveObject(FFocusedControl);
    FFocusedControl := nil;
  end;
end;

procedure TksVirtualListView.UpdateScrollLimmits;
var
  Targets: array of TAniCalculations.TTarget;
begin
  if FAniCalc <> nil then
  begin
    FAniCalc.OnStop := nil;
    FAniCalc.OnChanged := nil;
    SetLength(Targets, 2);
    Targets[0].TargetType := TAniCalculations.TTargetType.Min;
    Targets[0].Point := TPointD.Create(0, 0);
    Targets[1].TargetType := TAniCalculations.TTargetType.Max;

    FMaxScrollPos := Round(Max((FTotalItemHeight - Height), 0));
    //if FMaxScrollPos < FScrollPos then
    //  FScrollPos := FMaxScrollPos;
    Targets[1].Point := TPointD.Create(100, FMaxScrollPos);
    FAniCalc.SetTargets(Targets);

    FAniCalc.ViewportPosition := PointF(0, FScrollPos);
    FAniCalc.OnChanged := AniCalcChange;
    FAniCalc.OnStop := AniCalcStop;
  end;
  FScrollBar.Max := FTotalItemHeight;
  FScrollBar.ViewportSize := Height;
  FScrollBar.Position.y := 0;
  FScrollBar.Position.x := Width - FScrollBar.Width;
  FScrollBar.Height := Height;
  FScrollBar.Visible := FTotalItemHeight > Height;
end;

function TksVirtualListView.CreateTimer(AInterval: integer; AProc: TTimerProc)
  : TFmxHandle;
begin
  Result := 0;
  if FTimerService <> nil then
    Result := FTimerService.CreateTimer(AInterval, AProc);
end;

procedure TksVirtualListView.KillTimer(var ATimer: TFmxHandle);
begin
  if FTimerService <> nil then
  begin
    if (ATimer <> 0) then
    begin
      FTimerService.DestroyTimer(ATimer);
      ATimer := 0;
    end;

  end;
end;

procedure TksVirtualListView.MouseDown(Button: TMouseButton; Shift: TShiftState;
  x, y: single);
var
  ABtn: TksVListActionButton;
  ACanDelete: Boolean;
//  ATask: ITask;
begin
  inherited;
  if FScrollPos < 0 then
    Exit;
  KillTimer(FLongTapTimer);

  FMouseDownTime := Now;
  FMouseDownPos := PointF(x, y);
  FAniCalc.MouseDown(x, y);
  FMouseDownItem := FItems.ItemAtPos(x, y);

  if (FMouseDownItem <> nil) and (FMouseDownItem.FOffset <> 0) then
  begin
    ABtn := FMouseDownItem.FActionButtons.ButtonAtXY(x, y);
    if ABtn <> nil then
    begin
      FAniCalc.MouseUp(x, y);
      if ABtn.IsDeleteButton then
      begin
        ACanDelete := True;
        if Assigned(FCanDeleteItem) then
          FCanDeleteItem(Self, FMouseDownItem, ACanDelete);
        if ACanDelete then
        begin
          FMouseDownItem.DeleteItem;
          Exit;
        end;
      end
      else
      begin

        if Assigned(FOnActionButtonClick) then
          FOnActionButtonClick(Self, FMouseDownItem, ABtn);
      end;
    end;
    FMouseDownItem.SlideIn;
    FMouseDownItem := nil;
    FAniCalc.MouseLeave;
    Exit;
  end;

  ResetItemOffsets(nil);

  if FMouseDownItem <> nil then
    FLongTapTimer := CreateTimer(C_LONG_TAP_DURATION, LongTapTimerProc)
end;

procedure TksVirtualListView.MouseMove(Shift: TShiftState; x, y: single);
begin
  FMousePt := PointF(x, y);
  if FAniCalc.Down then
    FAniCalc.MouseMove(x, y);
  if (ssLeft in Shift) then
    FPendingRefresh := ((ScrollPos <= -50) and (FAniCalc.Down));
  if (FAniCalc.Down) and (FMouseDownPos.y <> y) then
  begin
    if FSelectionOptions.KeepSelection = False then
      DeselectAll;
  end;
end;

procedure TksVirtualListView.MouseUp(Button: TMouseButton; Shift: TShiftState;
  x, y: single);
var
  ATapRect: TRectF;
  ASwipeRect: TRectF;
  ATapDuration: integer;
  AItem: TksVListItem;
  ASwipeDirection: TksVListSwipeDirection;
  ADidSwipe: Boolean;
begin
  inherited;
  if FMouseDownItem <> nil then
  begin
    if (FMouseDownItem.State in [Deleting, Deleted, Sliding]) then
    begin
      Exit;
    end;
  end;

  // check for quick tap (within 300 ms)
  FAniCalc.MouseUp(x, y);

  if (FMouseDownItem <> nil) and (FMouseDownItem.FOffset <> 0) then
  begin
    if (FMouseDownItem.State in [Deleting, Deleted]) then
      Exit;
    // check for action button tap...
    if FMouseDownItem.State = Normal then
    begin
      FMouseDownItem.SlideIn;
      Exit;
    end;
  end;

  ATapRect := RectF(FMouseDownPos.x - 8, FMouseDownPos.y - 8,
    FMouseDownPos.x + 8, FMouseDownPos.y + 8);
  ASwipeRect := RectF(0, FMouseDownPos.y - 32, Width, FMouseDownPos.y + 32);
  ATapDuration := MilliSecondsBetween(FMouseDownTime, Now);

  AItem := FMouseDownItem;
  if AItem <> nil then
  begin
    // swipe...
    ADidSwipe := False;
    if PtInRect(ASwipeRect, PointF(x, y)) then
    begin

      if ATapDuration <= C_LONG_TAP_DURATION then
      begin
        // swipe
        if (x < FMouseDownPos.x - 16) or (x > FMouseDownPos.x + 16) then
        begin
          if x < (FMouseDownPos.x) then
            ASwipeDirection := ksSwipeFromRight
          else
            ASwipeDirection := ksSwipeFromLeft;

          DoItemSwiped(AItem, ASwipeDirection);
          FMouseDownItem := nil;
          Exit;
        end;
      end;
    end;

    // tap and long tap
    if (PtInRect(ATapRect, PointF(x, y))) and (ADidSwipe = False) then
    begin
      if ATapDuration <= C_LONG_TAP_DURATION then
      begin
        // tap
        DoItemClicked(AItem, True);
      end
      else
      begin
        // long tap
        DoItemLongTap(AItem);

      end;
    end;

  end;


  if FSelectionOptions.FKeepSelection = False then
    DeselectAll;

end;

procedure TksVirtualListView.MouseWheel(Shift: TShiftState; WheelDelta: integer;
  var Handled: Boolean);
var
  Offset: single;
  ANewPos: single;
begin
  inherited;
  if (csDesigning in ComponentState) then
    Exit;
  if (not Handled) then
  begin
    if not(ssHorizontal in Shift) then
    begin
      FAniCalc.UpdatePosImmediately;
      Offset := Height / 14;
      Offset := Offset * -1 * (WheelDelta / 120);
      ANewPos := Max(FScrollPos + Offset, 0);
      ANewPos := Min(ANewPos, (Max((FTotalItemHeight - Height), 0)));
      ScrollTo(Floor(ANewPos));
      Handled := True;
    end
  end;
end;

{ TksVListItemList }


function TksVListItemList.Add: TksVListItem;
begin
  Result := TksVListItem.Create(Self);
  Add(Result);
  Result.Background := FOwner.Appearence.ItemBackground;
  Result.OnEditInput := FOwner.DoItemEditInput;
  Result.OnDateSelected := FOwner.DoItemDateSelected;
  Result.OnTimeSelected := FOwner.DoItemTimeSelected;
  Result.BeforeSelectPickerItem := FOwner.DoBeforeItemPickerSelected;
  Result.OnSelectPickerItem := FOwner.DoItemPickerSelected;
  Changed(True);
end;

function TksVListItemList.Add(ATitle, ASubTitle, ADetail: string;
  const AAccessory: TksAccessoryType = atNone): TksVListItem;
begin
  Result := Add;
  Result.Title.Text := ATitle;
  Result.Title.Font.Size := 13;
  Result.SubTitle.Text := ASubTitle;
  Result.SubTitle.Font.Size := 13;

  Result.Detail.Text := ADetail;
  Result.Detail.Font.Size := 13;
  Result.Accessory.AccessoryType := AAccessory;
  Changed(True);
end;

function TksVListItemList.Add(ATitle, ASubTitle, ADetail: string; AImage: TBitmap; const AAccessory: TksAccessoryType = atNone): TksVListItem;
begin
  Result := Add(ATitle, ASubtitle, ADetail, AAccessory);
  Result.Image.Bitmap := AImage;
end;

function TksVListItemList.AddChatBubble(AText, ASender: string; AColor, ATextColor: TAlphaColor; ALeftAlign: Boolean): TksVListItem;
begin
  Result := Add;
  with Result.AddChatBubble(AText, ASender, not ALeftAlign) do
  begin
    FColor := AColor;
    FTextColor := ATextColor;
  end;
end;

function TksVListItemList.AddHeader(AText: string): TksVListItem;
begin
  Result := Add(AText, '', '');
  //Result.BeginUpdate;
  try
    Result.Background := GetColorOrDefault(FOwner.Appearence.HeaderColor, claNull);
    Result.Title.Font.Size := 13;
    Result.Title.TextSettings.FontColor := claBlack;
    Result.Detail.Font.Size := 12;
    Result.Detail.TextSettings.FontColor := claDimgray;

    Result.Purpose := Header;
    Result.CanSelect := False;
    Result.Title.VertAlign := TVerticalAlignment.taAlignBottom;
  finally
  //  Result.EndUpdate;
  end;
end;

function TksVListItemList.AddInputSelector(ATitle, ASubTitle, ADetail,
  ATagStr: string): TksVListItem;
begin
  Result := Add(ATitle, ASubTitle, ADetail, nil, atMore);
  Result.SelectorType := TksVListItemSelectorType.ksSelectorEdit;
  Result.TagStr := ATagStr;
end;

function TksVListItemList.AddPickerSelector(ATitle, ASubTitle, ADetail: string;
  AImage: TBitmap; ATagStr: string): TksVListItem;
begin
  Result := Add(ATitle, ASubTitle, ADetail, AImage, atMore);
  Result.SelectorType := TksVListItemSelectorType.ksSelectorPicker;
  Result.TagStr := ATagStr;
end;

function TksVListItemList.AddDateSelector(ATitle, ASubTitle: string; ASelected: TDateTime;
  AImage: TBitmap; ATagStr: string): TksVListItem;
var
  AStr: string;
begin
  AStr := '';
  if ASelected > 0 then
    AStr := FormatDateTime('ddd, dd mmm, yyyy', ASelected);
  Result := Add(ATitle, ASubTitle, AStr, AImage, atMore);
  Result.FSelectedDate := ASelected;
  Result.SelectorType := TksVListItemSelectorType.ksSelectorDate;
  Result.TagStr := ATagStr;
end;

function TksVListItemList.AddTimeSelector(ATitle, ASubTitle: string; ASelected: TDateTime;
  AImage: TBitmap; ATagStr: string): TksVListItem;
begin
  Result := Add(ATitle, ASubTitle, FormatDateTime('hh:nn', ASelected), AImage, atMore);
  Result.FSelectedTime := ASelected;
  Result.SelectorType := TksVListItemSelectorType.ksSelectorTime;
  Result.TagStr := ATagStr;
end;

function TksVListItemList.Insert(AIndex: integer;
  ATitle, ASubTitle, ADetail: string;
  const AAccessory: TksAccessoryType = atNone): TksVListItem;
begin
  Result := TksVListItem.Create(Self);
  Result.Title.Text := ATitle;
  Result.SubTitle.Text := ASubTitle;
  Result.Detail.Text := ADetail;
  Result.Accessory.AccessoryType := AAccessory;
  //FItems.
  inherited Insert(AIndex, Result);
  Changed(True);
end;

procedure TksVListItemList.Clear;
begin
  inherited Clear;
  //Clear;
  Changed(True);
end;
      {
procedure TksVListItemList.ClearCachesAfterIndex(AIndex: integer);
var
  ICount: integer;
begin
  for ICount := AIndex to Count - 1 do
    Items[ICount].ClearCache;
end;}
         {
procedure TksVListItemList.ClearCachesBeforeIndex(AIndex: integer);
var
  ICount: integer;
begin
  for ICount := AIndex downto 0 do
    Items[ICount].ClearCache;
end;    }

constructor TksVListItemList.Create(AOwner: TksVirtualListView);
begin
  inherited Create;
  //FItems := TObjectList<TksVListItem>.Create;
  FOwner := AOwner;
end;

procedure TksVListItemList.Delete(AIndex: integer; AAnimate: Boolean);
begin
  if (AIndex < 0) or (AIndex > (Count - 1)) then
    Exit;
  if AAnimate then
    //FItems
    items[AIndex].DeleteItem
  else
  begin
    //itemsFItems.
    Delete(AIndex);
    FOwner.UpdateScrollLimmits;
    FOwner.DoItemDeleted;

  end;
end;

procedure TksVListItemList.Delete(AItem: TksVListItem; const AAnimate: Boolean = False);
begin
  //FItems.Delete(FItems.IndexOf(AItem));
  Delete(IndexOf(AItem), AAnimate);
end;

destructor TksVListItemList.Destroy;
begin
  //ClearCachesAfterIndex(0);
  //FreeAndNil(FItems);
  inherited;
end;

function TksVListItemList.GetCheckedCount: integer;
var
  ICount: integer;
begin
  Result := 0;
  for ICount := 0 to Count-1 do
    if Items[ICount].Checked then
      Result := Result +1;
end;
       {
function TksVListItemList.GetCount: integer;
begin
  Result := FItems.Count;
end;


function TksVListItemList.IndexOf(AItem: TksVListItem): integer;
begin
  Result := FItems.IndexOf(AItem);
end;

function TksVListItemList.GetItem(index: integer): TksVListItem;
begin
  Result := FItems[index];
end;     }

function TksVListItemList.ItemAtPos(x, y: single): TksVListItem;
var
  ICount: integer;
begin
  Result := nil;
  y := y + FOwner.ScrollPos;

  for ICount := 0 to Count - 1 do
  begin
    if PtInRect(Items[ICount].ItemRect, PointF(x, y)) then
    begin
      Result := Items[ICount];
      Exit;
    end;
  end;
end;


procedure TksVListItemList.Changed(AUpdateScrollLimits: Boolean);
begin
  if FOwner.FUpdateCount > 0 then
    Exit;
  if AUpdateScrollLimits then
  begin
    UpdateItemRects;
    FOwner.UpdateScrollLimmits;
  end;
  FOwner.Invalidate;
end;

procedure TksVListItemList.UpdateItemRects;
var
  ICount: integer;
  ARect: TRectF;
  AYPos: integer;
  AItem: TksVListItem;
begin
  AYPos := 0;
  FOwner.FTotalItemHeight := 0;
  for ICount := 0 to Count - 1 do
  begin
    AItem := Items[ICount];
    AItem.FAbsoluteIndex := ICount;
    AItem.FIndex := ICount;
    ARect := RectF(0, AYPos, FOwner.Width, AYPos + AItem.Height);

    AItem.Title.FMaxWidth := Round(FOwner.Width-50);
    AItem.SubTitle.FMaxWidth := Round(FOwner.Width-50);

    AItem.FItemRect := ARect;
    AYPos := AYPos + AItem.Height;
    FOwner.FTotalItemHeight := FOwner.FTotalItemHeight + AItem.Height;
  end;
end;

{ TksVListItemTextObject }


function TksVListItemTextObject.ActualTextWidth: single;
var
  ARect: TRectF;
begin
  if FActualTextWidth > 0 then
  begin
    Result := FActualTextWidth;
    Exit;
  end;

  ARect := RectF(0, 0, FWidth, MaxSingle);
  if ARect.Width = 0 then
    ARect.Width := MaxSingle;

  TCanvasManager.MeasureCanvas.Font.Assign(FTextSettings.Font);
  TCanvasManager.MeasureCanvas.MeasureText(ARect, FText, FTextSettings.WordWrap, [], FTextSettings.HorzAlign, TTextAlign.Leading);
  Result := ARect.Width;
  FActualTextWidth := ARect.Width;
end;

procedure TksVListItemTextObject.BeforeRenderText(ACanvas: TCanvas; ARect: TRectF);
begin
  //
end;

function TksVListItemTextObject.CalculateSize: TSizeF;
begin
  Result.Width := CalculateTextWidth(FText, FTextSettings.Font, FTextSettings.WordWrap, FMaxWidth, 0);
  Result.Height := CalculateTextHeight(FText, FTextSettings.Font, FTextSettings.WordWrap, FTextSettings.Trimming, Result.Width, 0);
  FWidth := Result.Width;
  FHeight := Result.Height;
end;

function TksVListItemTextObject.CalculateWidth: single;
begin
  Result := CalculateTextWidth(FText, FTextSettings.Font, False);
end;

procedure TksVListItemTextObject.Changed;
begin
  {$IFDEF IOS}
  FCached.Clear(claNull);
  {$ENDIF}
  FTextSize := Point(0, 0);
  CalculateSize;
  //FCachedSize := FCachedSize.Empty;
  //if FCached = nil then
  //  Exit;
  {if FCached.IsEmpty = False then
  begin
    FCached.Clear(claNull);
    FCached.SetSize(0, 0);
    FWidth := 0;
  end;   }
  inherited;
end;

procedure TksVListItemTextObject.ClearCache;
begin
  inherited;
  {$IFDEF IOS}
  FreeAndNil(FCached);
  FCached := TBitmap.Create;
  {$ENDIF}
end;

{

procedure TksVListItemTextObject.ClearCache;
begin
  //FreeAndNil(FCached);
  FActualTextWidth := 0;
end;   }

constructor TksVListItemTextObject.Create(AItem: TksVListItem);
begin
  inherited Create(AItem);
  {$IFDEF IOS}
  FCached := TBitmap.Create;
  {$ENDIF}
  FTextSize := PointF(0, 0);
 //FPathData := nil;
  FTextLayout := TTextLayoutManager.DefaultTextLayout.Create;
  FTextSettings := TTextSettings.Create(nil);
  FTextSettings.Trimming := TTextTrimming.Character;
  FMaxWidth := 0;
  FActualTextWidth := 0;
  FText := '';
  //FCached := nil;
end;

destructor TksVListItemTextObject.Destroy;
begin
  {$IFDEF IOS}
  FreeAndNil(FCached);
  {$ENDIF}
  FreeAndNil(FTextSettings);
  FreeAndNil(FTextLayout);
  //FreeAndNil(FCached);
  inherited;
end;

procedure TksVListItemTextObject.DrawToCanvas(ACanvas: TCanvas;
  AItemRect: TRectF);
var
  ARect: TRectF;
  ATextColor: TAlphaColor;
begin
  if (FText = '') or (FVisible = False) then
    Exit;

  if FTextSize.IsZero then
  begin
    FTextSize := CalculateSize;
    ARect := CalcObjectRect(AItemRect);

    if (FMaxWidth > 0) and (FMaxWidth < ARect.Width) then
      ARect.Width := FMaxWidth;

    FTextLayout.BeginUpdate;
    FTextLayout.Text := FText;
    FTextLayout.WordWrap := FTextSettings.WordWrap;
    FTextLayout.Font.Assign(FTextSettings.Font);
    FTextLayout.HorizontalAlign := FTextSettings.HorzAlign;
    FTextLayout.VerticalAlign := FTextSettings.VertAlign;
    FTextLayout.Padding.Rect := RectF(0,0,0,0);
    FTextLayout.Trimming := FTextSettings.Trimming;
    if FTextSettings.WordWrap  then
      FTextLayout.Trimming := TTextTrimming.None;
    FTextLayout.TopLeft := PointF(ARect.Left, ARect.Top);
    FTextLayout.MaxSize := PointF(ARect.Width, ARect.Height);
    FTextLayout.EndUpdate;
  end;

  ARect := CalcObjectRect(AItemRect);
  FTextLayout.TopLeft := PointF(ARect.Left, ARect.Top);

  ACanvas.Font.Assign(FTextSettings.Font);

  ATextColor := FTextSettings.FontColor;

  if (FOwner.Selected) and (FOwner.FOwner.FOwner.Appearence.SelectedFontColor <> claNull) then
    ATextColor := FOwner.FOwner.FOwner.Appearence.SelectedFontColor;

  FTextLayout.Color := ATextColor;

  {$IFDEF IOS}
  if (FCached.IsEmpty) then
  begin
    FCached.SetSize(Round(FWidth*GetScreenScale), Round(FHeight*GetScreenScale));
    FCached.BitmapScale := GetScreenScale;
    FCached.Clear(claNull);
    FCached.Canvas.BeginScene;
    FTextLayout.Color := ATextColor;
    FTextLayout.TopLeft := PointF(0, 0);
    FTextLayout.RenderLayout(FCached.Canvas);
    FCached.Canvas.EndScene;
    FTextLayout.TopLeft := PointF(ARect.Left, ARect.Top);
  end;
  ACanvas.DrawBitmap(FCached, RectF(0, 0, FCached.Width, FCached.Height), ARect, 1, False);
  {$ELSE}
  FTextLayout.RenderLayout(ACanvas);
  {$ENDIF}

 // ACanvas.DrawRect(ARect, 0, 0, AllCorners, 1);
{  RenderText(ACanvas,
           ARect.Left,
           ARect.Top,
           ARect.Width,
           ARect.Height,
           FText,
           ACanvas.Font,
           //FCached.Canvas.Font,
           ATextColor,
           FTextSettings.WordWrap,
           FTextSettings.HorzAlign,
           FTextSettings.VertAlign,
           FTextSettings.Trimming,
           0);  }
end;

function TksVListItemTextObject.GetFont: TFont;
begin
  Result := FTextSettings.Font;
end;

procedure TksVListItemTextObject.SetFont(const Value: TFont);
begin
  FTextSettings.Font.Assign(Value);
  Changed;
end;

procedure TksVListItemTextObject.SetMaxWidth(const Value: integer);
begin
  if FMaxWidth <> Value then
  begin
    FMaxWidth := Value;
    Changed;
  end;
end;

procedure TksVListItemTextObject.SetText(const Value: string);
begin
  if FText <> Value then
  begin
    FText := Value;
    Changed;
  end;
end;

{ TksVListItemBaseObject }

function TksVListItemBaseObject.CalcObjectRect(AItemRect: TRectF): TRectF;
var
  ALeft: single;
begin
  ALeft := Left;
  if FUsePercentForXPos then
    ALeft := (AItemRect.Width / 100) * ALeft;

  Result := RectF(ALeft, Top, ALeft + (FWidth), Top + (FHeight));

  OffsetRect(Result, AItemRect.Left, AItemRect.Top);

  case FVertAlign of
    taVerticalCenter: OffsetRect(Result, 0, (AItemRect.Height - FHeight) / 2);
    taAlignBottom: OffsetRect(Result, 0, AItemRect.Height - FHeight);
  end;

  case FHorzAlign of
    taCenter: OffsetRect(Result, (AItemRect.Width - FWidth) / 2, 0);
    taRightJustify:
    begin
      OffsetRect(Result, (AItemRect.Width - FWidth), 0);
      //Result.Right := Result.Right - C_ACCESSORY_WIDTH;
    end;
  end;
end;

procedure TksVListItemBaseObject.Changed;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
  if FOwner <> nil then
    FOwner.Changed;
end;

procedure TksVListItemBaseObject.ClearCache;
begin
  //
end;

constructor TksVListItemBaseObject.Create(AItem: TksVListItem);
begin
  inherited Create;
  FOwner := AItem;
  FVisible := True;
  FVertAlign := TVerticalAlignment.taVerticalCenter;
  FUsePercentForXPos := False;
end;

procedure TksVListItemBaseObject.DrawToCanvas(ACanvas: TCanvas;
  AItemRect: TRectF);
begin
  //
end;

procedure TksVListItemBaseObject.SetHeight(const Value: single);
begin
  FHeight := Value;
  Changed;
end;

procedure TksVListItemBaseObject.SetHorzAlign(const Value: TAlignment);
begin
  if FHorzAlign <> Value then
  begin
    FHorzAlign := Value;
    Changed;
  end;
end;

procedure TksVListItemBaseObject.SetLeft(const Value: single);
begin
  FLeft := Value;
  Changed;
end;

procedure TksVListItemBaseObject.SetTop(const Value: single);
begin
  FTop := Value;
  Changed;
end;

procedure TksVListItemBaseObject.SetUsePercentForXPos(const Value: Boolean);
begin
  if FUsePercentForXPos <> Value then
  begin
    FUsePercentForXPos := Value;
    Changed;
  end;
end;

procedure TksVListItemBaseObject.SetVertAlign(const Value: TVerticalAlignment);
begin
  if FVertAlign <> Value then
  begin
    FVertAlign := Value;
    Changed;
  end;
end;

procedure TksVListItemBaseObject.SetVisible(const Value: Boolean);
begin
  FVisible := Value;
end;

procedure TksVListItemBaseObject.SetWidth(const Value: single);
begin
  FWidth := Value;
  Changed;
end;

{ TksVListCheckBoxOptions }

procedure TksVListCheckBoxOptions.Changed;
begin
  FOwner.Invalidate;
end;

constructor TksVListCheckBoxOptions.Create(AOwner: TksVirtualListView);
begin
  inherited Create;
  FOwner := AOwner;
  FVisible := False;
  FMode := ksSingleSelect;
  FAlignment := ksCbRightAlign;
end;

procedure TksVListCheckBoxOptions.SetAlignment(const Value
  : TksVListCheckBoxAlign);
begin
  if FAlignment <> Value then
  begin
    FAlignment := Value;
    Changed;
  end;
end;

procedure TksVListCheckBoxOptions.SetMode(const Value: TksSelectionType);
begin
  if FMode <> Value then
  begin
    FMode := Value;
    Changed;
  end;
end;

procedure TksVListCheckBoxOptions.SetVisible(const Value: Boolean);
begin
  if FVisible <> Value then
  begin
    FVisible := Value;
    Changed;
  end;
end;

{ TksVListSelectionOptions }

procedure TksVListSelectionOptions.Changed;
begin
  FOwner.Invalidate;
end;

constructor TksVListSelectionOptions.Create(AOwner: TksVirtualListView);
begin
  inherited Create;
  FOwner := AOwner;
  FSelectionType := ksSingleSelect;
  FKeepSelection := False;
end;

procedure TksVListSelectionOptions.SetKeepSelection(const Value: Boolean);
begin
  if FKeepSelection <> Value then
  begin
    FKeepSelection := Value;
    Changed;
  end;
end;

procedure TksVListSelectionOptions.SetSelectionType
  (const Value: TksSelectionType);
begin
  if Value <> FSelectionType then
  begin
    FSelectionType := Value;
    if FSelectionType = ksMultiSelect then
      FKeepSelection := True;
    Changed;
  end;
end;

{ TksVListItemImageObject }

constructor TksVListItemImageObject.Create(AItem: TksVListItem);
begin
  inherited;
  //FOwnsImage := True;
  FBitmap := TBitmap.Create;;
  FRenderImage := TBitmap.Create;
  //FCached := nil;
  FBackground := claNull;
  FOpacity := 1;
end;

destructor TksVListItemImageObject.Destroy;
begin
  FreeAndNil(FBitmap);
  FreeAndNil(FRenderImage);
  inherited;
end;

procedure TksVListItemImageObject.DrawToCanvas(ACanvas: TCanvas;
  AItemRect: TRectF);
var
  ARect: TRectF;
  ABmp: TBitmap;
begin
  inherited;
  ARect := CalcObjectRect(AItemRect);
  if FBackground <> claNull then
  begin
    ACanvas.Fill.Color := FBackground;
    ACanvas.Fill.Kind := TBrushKind.Solid;
    ACanvas.FillRect(ARect, 6, 6, AllCorners, 1);
    InflateRect(ARect, -4, -4);
  end;

  if FRenderImage.IsEmpty then
    FRenderImage.Assign(FBitmap);

  if (Self is TksVListItemAccessoryObject) and
     (FOwner.Selected) and
     (FOwner.FOwner.FOwner.Appearence.SelectedFontColor <> claNull) then
  begin
    ABmp := TBitmap.Create;
    try
      ABmp.Assign(FRenderImage);
      ReplaceOpaqueColor(ABmp, FOwner.FOwner.FOwner.Appearence.SelectedFontColor);
      ACanvas.DrawBitmap(ABmp, RectF(0, 0, ABmp.Width, ABmp.Height), ARect, FOpacity, False);
    finally
      FreeAndNil(ABmp);
    end;
  end
  else
  begin

    //if FImageShape = ksImageRect then
      ACanvas.DrawBitmap(FRenderImage, RectF(0, 0, FBitmap.Width, FBitmap.Height), ARect, FOpacity, True);
   // else
    begin
      // circle cropping...
      {ABmp := TBitmap.Create(FBitmap.Width, FBitmap.Height);
      try
        ABmp.Canvas.BeginScene;
        ABmp.Canvas.Fill.Bitmap.Bitmap := FBitmap;
        ABmp.Canvas.Fill.Kind := TBrushKind.Bitmap;
        ABmp.Canvas.FillEllipse(RectF(0, 0, FBitmap.Width, FBitmap.Height), 1);
        ABmp.Canvas.EndScene;

        ACanvas.DrawBitmap(ABmp, RectF(0, 0, FBitmap.Width, FBitmap.Height), ARect, FOpacity, True);
        ABmp.Free;

        ABmp := TBitmap.Create(Round(ARect.Width*4), Round(ARect.Height*4));

        ABmp.Clear(claNull);
        ABmp.Canvas.BeginScene;
        ABmp.Canvas.Stroke.Thickness := 2;
        ABmp.Canvas.Stroke.Color := claDimgray;
        ABmp.Canvas.Stroke.Kind := TBrushKind.Solid;
        ABmp.Canvas.DrawEllipse(RectF(1, 1, ABmp.Width-1, ABmp.Height-1), 1);
        ABmp.Canvas.EndScene;

        ACanvas.DrawBitmap(ABmp, RectF(0, 0, ABmp.Width, ABmp.Height), ARect, FOpacity, True);
        //ACanvas.Stroke.Color := claDimgray;
        //ACanvas.Stroke.Kind := TBrushKind.Solid;
        //ACanvas.DrawEllipse(ARect, 1);

      finally
        ABmp.Free;
      end; }
    end;
  end;
end;

function TksVListItemImageObject.GetIsEmpty: Boolean;
begin
  Result := FBitmap = nil;
  if not Result then
    Result := FBitmap.IsEmpty;
end;

procedure TksVListItemImageObject.SetBackground(const Value: TAlphaColor);
begin
  if FBackground <> Value then
  begin
    if Value = claNull then
      Exit;
    FBackground := Value;
    Changed;
  end;
end;

procedure TksVListItemImageObject.SetBitmap(const Value: TBitmap);
begin
  (*FOwnsImage := True;
  //if FOwnsImage then
  begin
    if FBitmap = nil then
    begin
      {if FWidth = 0 then FWidth := Value.Width / GetScreenScale;
      if FHeight = 0 then FHeight := Value.Height / GetScreenScale;

      FBitmap := TBitmap.Create(Round(FWidth*GetScreenScale), Round(FHeight*GetScreenScale));
      FBitmap.Clear(claNull);
                               }
      FBitmap := TBitmap.Create;
      FBitmap.Assign(Value);
    end;
    {FBitmap.Canvas.BeginScene;
    try
      FBitmap.Canvas.DrawBitmap(Value, RectF(0, 0, Value.Width, Value.Height),
        RectF(0, 0, FBitmap.Width, FBitmap.Height), 1, False);
    finally
      FBitmap.Canvas.EndScene;
    end;    }
  end
  //else
  //  FBitmap := Value;*)
  FBitmap.Clear(claNull);
  FBitmap.Assign(Value);
end;

procedure TksVListItemImageObject.SetImageShape(const Value: TksImageShape);
var
  ABmp: TBitmap;
begin
  if FImageShape <> Value then
  begin
    FImageShape := Value;

    FRenderImage.Assign(FBitmap);
    if Value = ksImageCircle then
    begin
      if FBitmap.IsEmpty then
        Exit;
      FRenderImage.Clear(claNull);
      ABmp := TBitmap.Create(FBitmap.Width, FBitmap.Height);
      try
        ABmp.Clear(claNull);
        ABmp.Canvas.BeginScene;
        ABmp.Canvas.Fill.Bitmap.Bitmap := FBitmap;
        ABmp.Canvas.Fill.Kind := TBrushKind.Bitmap;
        ABmp.Canvas.FillEllipse(RectF(0, 0, FBitmap.Width, FBitmap.Height), 1);
        ABmp.Canvas.EndScene;
        FRenderImage.Assign(ABmp);
      finally
        ABmp.Free;
      end;
    end;
    Changed;
  end;
end;

procedure TksVListItemImageObject.SetOpacity(const Value: single);
begin
  FOpacity := Value;
  Changed;
end;

procedure TksVListItemImageObject.SetOpaqueColor(AColor: TAlphaColor);
begin
  if AColor = claNull then
    Exit;
  ReplaceOpaqueColor(FBitmap, AColor);
  Changed;
end;

procedure TksVListItemImageObject.SetProperties(ABitmap: TBitmap; AOpaqueColor,
  ABackgroundColor: TAlphaColor);
begin
  Bitmap := ABitmap;
  SetOpaqueColor(AOpaqueColor);
  SetBackground(ABackgroundColor);
end;
{
procedure TksVListItemImageObject.SetTintColor(const Value: TAlphaColor);
begin
  FTintColor := Value;
  Changed;
end;  }

{ TksVListItemAccessoryObject }

constructor TksVListItemAccessoryObject.Create(AItem: TksVListItem);
begin
  inherited;
  FAccessoryType := atNone;
  FColor := claNull;
end;

procedure TksVListItemAccessoryObject.DrawToCanvas(ACanvas: TCanvas;
  AItemRect: TRectF);
var
  ABmp: TBitmap;
begin
  {if FAccessoryType <> atNone then
  begin
    Bitmap := AAccessories.GetAccessoryImage(FAccessoryType);
    FWidth := Bitmap.Width/GetScreenScale(False);
    FHeight := Bitmap.Height/GetScreenScale(False);
    inherited;
  end;  }
  //inherited;

  ABmp := AAccessories.GetAccessoryImage(FAccessoryType);

  //if Bitmap <> nil then
  //begin
  //frmMain.imgAvailable.Bitmap := AAccessories.GetAccessoryImage(atMore);

  if (ABmp.Width > 0) and (ABmp.Height > 0) then
  begin
    FWidth := ABmp.Width/GetScreenScale(False);
    FHeight := ABmp.Height/GetScreenScale(False);
    ACanvas.DrawBitmap(ABmp, RectF(0, 0, ABmp.Width, ABmp.Height), CalcObjectRect(AItemRect), 1, True);
  end;

  //end;
  //ACanvas.Stroke.Color := claBlack;
  //ACanvas.DrawRect(CalcObjectRect(AItemRect), 0, 0, AllCorners, 1);
end;


procedure TksVListItemAccessoryObject.RedrawAccessory;
begin
  Bitmap := AAccessories.GetAccessoryImage(FAccessoryType);

  {FreeAndNil(FBitmap);
  Bitmap := AAccessories.GetAccessoryImage(FAccessoryType);
  if FColor <> claNull then
    SetOpaqueColor(FColor);

  if Bitmap.IsEmpty then
  begin
    FWidth := 0;
    FHeight := 0;
  end    }
  {else
  begin
    FWidth := Bitmap.Width / GetScreenScale;
    FHeight := Bitmap.Height / GetScreenScale;
  end;   }
end;

procedure TksVListItemAccessoryObject.SetAccessoryType
  (const Value: TksAccessoryType);
begin
  if FAccessoryType <> Value then
  begin
    FAccessoryType := Value;
    RedrawAccessory;
    Changed;
  end;
end;

{procedure TksVListItemAccessoryObject.SetBitmap(const Value: TBitmap);
begin
  inherited SetBitmap(Value);
  FWidth := FWidth / GetScreenScale;
  FHeight := FHeight / GetScreenScale;
end; }

{
procedure TksVListItemAccessoryObject.SetColor(const Value: TAlphaColor);
begin
  FOwnsImage := False;
  FColor := Value;
  if Value <> claNull then
  begin
    FOwnsImage := True;
    RedrawAccessory;
  end;
end;    }

{ TksVksListActionButton }

constructor TksVListActionButton.Create(AIsDelete: Boolean);
begin
  inherited Create;
  FIcon := TBitmap.Create;
  FTextColor := claWhite;
  FWidth := 80;
end;

destructor TksVListActionButton.Destroy;
begin
  FreeAndNil(FIcon);
  inherited;
end;

procedure TksVListActionButton.DrawToCanvas(ACanvas: TCanvas; ARect: TRectF);
var
  ATextRect: TRectF;
  AIconRect: TRectF;
begin
  FButtonRect := ARect;
  ACanvas.Fill.Kind := TBrushKind.Solid;
  ACanvas.Fill.Color := FColor;
  ACanvas.FillRect(ARect, 0, 0, AllCorners, 1);
  ACanvas.Fill.Color := FTextColor;
  ACanvas.Font.Size := 14;
  ATextRect := ARect;
  ATextRect.Height := CalculateTextHeight(FText, ACanvas.Font, False,
    TTextTrimming.Character);
  if FText = '' then
    ATextRect.Height := 0;

  if FIcon.IsEmpty = False then
  begin
    AIconRect := RectF(ARect.Left, ARect.Top, ARect.Left + (ARect.Height / 2.5),
      ARect.Top + (ARect.Height / 2.5));
    OffsetRect(AIconRect, (ARect.Width - AIconRect.Width) / 2,
      ((ARect.Height - AIconRect.Height) / 2));
    if FText <> '' then
      OffsetRect(AIconRect, 0, -6);
    OffsetRect(ATextRect, 0, AIconRect.Bottom - ATextRect.Top);
    // OffsetRect(ATextRect, 0, ((ARect.Height - AIconRect.Height) / 2) + ATextRect.Height);
    ACanvas.DrawBitmap(FIcon, RectF(0, 0, FIcon.Width, FIcon.Height),
      AIconRect, 1, False);
  end
  else
    OffsetRect(ATextRect, 0, (ARect.Height - ATextRect.Height) / 2);
  ACanvas.FillText(ATextRect, FText, False, 1, [], TTextAlign.Center,
    TTextAlign.Center);
end;

procedure TksVListActionButton.SetAccessory(const Value: TksAccessoryType);
begin
  FIcon.Assign(AAccessories.GetAccessoryImage(Value));
  FIcon.ReplaceOpaqueColor(FTextColor);

end;

procedure TksVListActionButton.SetTextColor(const Value: TAlphaColor);
begin
  FTextColor := Value;
  FIcon.ReplaceOpaqueColor(FTextColor);

end;

{ TksVListActionButtons }

function TksVListActionButtons.AddButton(AText: string;
  AColor, ATextColor: TAlphaColor; const AIcon: TksAccessoryType;
  const AWidth: integer): TksVListActionButton;
begin
  Result := TksVListActionButton.Create(False);
  Result.Width := AWidth;
  Result.Text := AText;
  Result.Color := AColor;
  Result.TextColor := ATextColor;
  Result.Accessory := AIcon;
  Add(Result);
end;

function TksVListActionButtons.ButtonAtXY(x, y: single): TksVListActionButton;
var
  ICount: integer;
begin
  Result := nil;
  for ICount := 0 to Count - 1 do
  begin
    if PtInRect(Items[ICount].FButtonRect, PointF(x, y)) then
    begin
      Result := Items[ICount];
      Exit;
    end;
  end;
end;

constructor TksVListActionButtons.Create(AOwner: TksVListItem);
begin
  inherited Create;
end;

procedure TksVListActionButtons.DrawToCanvas(ACanvas: TCanvas; ARect: TRectF);
var
  ICount: integer;
  AWidth: single;
  AXPos: single;
  ABtnRect: TRectF;
begin
  AXPos := 0;
  AWidth := ARect.Width / Count;
  for ICount := 0 to Count - 1 do
  begin
    ABtnRect := RectF(ARect.Left, ARect.Top, ARect.Left + AWidth, ARect.Bottom);
    OffsetRect(ABtnRect, AXPos, 0);
    Items[ICount].DrawToCanvas(ACanvas, ABtnRect);
    AXPos := AXPos + AWidth;
  end;
end;

function TksVListActionButtons.GetTotalWidth: integer;
var
  ICount: integer;
begin
  Result := 0;
  for ICount := 0 to Count - 1 do
    Result := Result + Items[ICount].Width;
end;

{ TksVListPullToRefreshOptions }

constructor TksVListPullToRefreshOptions.Create;
begin
  inherited Create;
  FPullText := 'PULL TO REFRESH';
  FReleaseText := 'RELEASE TO REFRESH';
  FEnabled := False;
end;

{ TksVListDeleteButton }

constructor TksVListDeleteButton.Create;
begin
  inherited Create;
  FColor := claRed;
  FTextColor := claWhite;
  FEnabled := False;
  FText := 'Delete';
  FShowImage := True;
  FWidth := 60;
end;

{ TksScrollBar }

constructor TksScrollBar.Create(AOwner: TComponent);
begin
  inherited;
  FDesignInteractive := False;
end;

{ TksVirtualListViewAppearence }

procedure TksVirtualListViewAppearence.Assign(ASource: TPersistent);
var
  Src : TksVirtualListViewAppearence;
begin
  if (ASource is TksVirtualListViewAppearence) then
  begin
    Src := TksVirtualListViewAppearence(ASource);

    FBackground                := Src.FBackground;
    FItemBackground            := Src.FItemBackground;
    FSeparatorColor            := Src.FSeparatorColor;
    FHeaderColor               := Src.FHeaderColor;
    FSelectedColor             := Src.FSelectedColor;
    FSelectedFontColor         := Src.SelectedFontColor;
  end
  else
    inherited;
end;

constructor TksVirtualListViewAppearence.Create(AListView: TksVirtualListView);
begin
  inherited Create;
  FListView := AListView;
  FItemBackground := claWhite;
  FBackground := claWhite;
  FSeparatorColor := claDarkgray;//$FFF0F0F0;
  FSelectedColor := C_VLIST_DEFAULT_SELECTED_COLOR;
  FSelectedFontColor := claNull;
  FHeaderColor := claNull;
  FHeaderFontColor := claNull;
end;

destructor TksVirtualListViewAppearence.Destroy;
begin
  inherited;
end;

procedure TksVirtualListViewAppearence.SetBackground(const Value: TAlphaColor);
begin
  FBackground := Value;
end;

procedure TksVirtualListViewAppearence.SetHeaderColor(const Value: TAlphaColor);
begin
  FHeaderColor := Value;
end;

procedure TksVirtualListViewAppearence.SetHeaderFontColor(const Value: TAlphaColor);
begin
  FHeaderFontColor := Value;
end;

procedure TksVirtualListViewAppearence.SetItemBackground(const Value: TAlphaColor);
begin
  FItemBackground := Value;
end;

procedure TksVirtualListViewAppearence.SetSelectedColor(
  const Value: TAlphaColor);
begin
  FSelectedColor := Value;
end;

procedure TksVirtualListViewAppearence.SetSelectedFontColor(const Value: TAlphaColor);
begin
  FSelectedFontColor := Value;
end;

procedure TksVirtualListViewAppearence.SetSeparatorBackground(
  const Value: TAlphaColor);
begin
  FSeparatorColor := Value;
end;

{ TksNoItemsText }

procedure TksNoItemsText.Changed;
begin
  FOwner.Invalidate;
end;

constructor TksNoItemsText.Create(AListView: TksVirtualListView);
begin
  inherited Create;
  FOwner := AListView;
  FFont := TFont.Create;
  FFont.Size := 18;
  FEnabled := False;
  FText := '';
  FTextColor := claSilver;
end;

destructor TksNoItemsText.Destroy;
begin
  FreeAndNil(FFont);
  inherited;
end;

procedure TksNoItemsText.DrawToCanvas(ACanvas: TCanvas; ARect: TRectF);
begin
  if FEnabled = False then
    Exit;
  ACanvas.Font.Assign(FFont);
  ACanvas.Fill.Color := FTextColor;
  ACanvas.FillText(ARect, FText, False, 1, [], TTextAlign.Center, TTextAlign.Center);
end;

procedure TksNoItemsText.SetEnabled(const Value: Boolean);
begin
  FEnabled := Value;
  Changed;
end;

procedure TksNoItemsText.SetFont(const Value: TFont);
begin
  FFont := Value;
  Changed;
end;

procedure TksNoItemsText.SetText(const Value: string);
begin
  FText := Value;
  Changed;
end;

{ TksVListItemShapeObject }

constructor TksVListItemShapeObject.Create(AItem: TksVListItem);
begin
  inherited;
  FStroke := TStrokeBrush.Create(TBrushKind.Solid, claBlack);
  FFill := TBrush.Create(TBrushKind.Solid, claNull);
  FCornerRadius := 0;
end;

destructor TksVListItemShapeObject.Destroy;
begin
  FreeAndNil(FStroke);
  FreeAndNil(FFill);
  inherited;
end;

procedure TksVListItemShapeObject.DrawToCanvas(ACanvas: TCanvas; AItemRect: TRectF);
var
  ARect: TRectF;
begin
  inherited;
  ARect := CalcObjectRect(AItemRect);
  ACanvas.FillRect(ARect, FCornerRadius, FCornerRadius, AllCorners, 1, FFill);
  ACanvas.DrawRect(ARect, FCornerRadius, FCornerRadius, AllCorners, 1, FStroke);
end;

{ TksVListItemBubbleObject }

constructor TksVListItemBubbleObject.Create(AItem: TksVListItem);
begin
  inherited;
  FColor := claDodgerblue;
  FTextColor := claWhite;
end;

procedure TksVListItemBubbleObject.SetColor(const Value: TAlphaColor);
begin
  FColor := Value;
  Changed;
end;

procedure TksVListItemBubbleObject.SetTextColor(const Value: TAlphaColor);
begin
  FTextColor := Value;
  Changed;
end;


{ TksVListObjectList }

procedure TksVListObjectList.ClearCache;
var
  ICount: integer;
begin
  for ICount := 0 to Count-1 do
    Items[ICount].ClearCache;
end;


end.

