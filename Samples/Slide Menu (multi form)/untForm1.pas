unit untForm1;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls, FMX.Controls.Presentation,
  FMX.Objects, ksTypes, FMX.TabControl, ksSlideMenu;

type
  TForm1 = class(TForm)
    ToolBar1: TToolBar;
    Label1: TLabel;
    SpeedButton1: TSpeedButton;
    ToolBar2: TToolBar;
    Image1: TImage;
    procedure SpeedButton1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses System.UIConsts, untMenu;

{$R *.fmx}

procedure TForm1.SpeedButton1Click(Sender: TObject);
begin
  dmMenu.ksSlideMenu1.OpenMenu(Self);
end;

end.
