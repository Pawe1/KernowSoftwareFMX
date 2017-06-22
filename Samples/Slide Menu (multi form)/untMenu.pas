unit untMenu;

interface

uses
  System.SysUtils, System.Classes, ksSlideMenu;

type
  TdmMenu = class(TDataModule)
    ksSlideMenu1: TksSlideMenu;
    procedure ksSlideMenu1BuildMenu(Sender: TObject;
      AItems: TksSlideMenuItemList);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  dmMenu: TdmMenu;

implementation

uses untForm1, untForm2, untForm3, ksTypes;

{%CLASSGROUP 'FMX.Controls.TControl'}

{$R *.dfm}

procedure TdmMenu.ksSlideMenu1BuildMenu(Sender: TObject;
  AItems: TksSlideMenuItemList);
begin
  AItems.AddItem('','First Form', Form1, TksStandardIcon.Calendar);
  AItems.AddItem('','Second Form', Form2, TksStandardIcon.BarChart);
  AItems.AddItem('','Third Form', Form3, TksStandardIcon.Settings);

end;

end.
