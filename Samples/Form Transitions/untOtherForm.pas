unit untOtherForm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, ksTableView,
  ksFormTransition, FMX.StdCtrls, FMX.Controls.Presentation, ksTypes,
  ksVirtualListView;

type
  TForm5 = class(TForm)
    ToolBar1: TToolBar;
    Label1: TLabel;
    Button1: TButton;
    ksFormTransition1: TksFormTransition;
    ksVirtualListView1: TksVirtualListView;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form5: TForm5;

implementation

{$R *.fmx}


procedure TForm5.Button1Click(Sender: TObject);
begin
  ksFormTransition1.Pop;
end;

procedure TForm5.FormCreate(Sender: TObject);
var
  ICount: integer;
begin
  {$IFDEF MSWINDOWS}
  Width := FormFactor.Width;
  Height := FormFactor.Height;
  Left := 360;
  Top := 150;
  {$ENDIF}

  for ICount := 1 to 5 do
  begin
    ksVirtualListView1.Items.Add('Setting '+InTtoStr(ICount), '', '');
  end;

end;


//--------------

end.
