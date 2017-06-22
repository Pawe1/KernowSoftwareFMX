unit untMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, System.Net.URLClient,
  System.Net.HttpClient, System.Net.HttpClientComponent, FMX.StdCtrls, ksTableView,
  FMX.Controls.Presentation, ksNetHttpClient, FMX.ScrollBox, FMX.Memo, FMX.Objects, ksLoadingIndicator, ksTypes,
  ksProgressBar;

type
  TForm33 = class(TForm)
    ToolBar1: TToolBar;
    ToolBar2: TToolBar;
    Button1: TButton;
    Button2: TButton;
    Label1: TLabel;
    ksNetHttpClient1: TksNetHttpClient;
    ksProgressBar1: TksProgressBar;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure ksNetHttpClient1ReceiveData(const Sender: TObject; AContentLength, AReadCount: Int64; var Abort: Boolean);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form33: TForm33;

implementation

{$R *.fmx}

procedure TForm33.Button1Click(Sender: TObject);
var
  AResponse: IHTTPResponse;
begin
  // standard (blocking) get method...
  ShowLoadingIndicator(Self);
  try
    //Memo1.Lines.Clear;
    Application.ProcessMessages;
    AResponse := ksNetHttpClient1.Get('http://download.thinkbroadband.com/1MB.zip');
  finally
    HideLoadingIndicator(Self);
  end;
end;

procedure TForm33.Button2Click(Sender: TObject);
var
  AResponse: IHTTPResponse;
begin
  // async get...
  ShowLoadingIndicator(Self);
  try
    //Memo1.Lines.Clear;
    Application.ProcessMessages;
    AResponse := ksNetHttpClient1.GetAsyncWait('http://download.thinkbroadband.com/1MB.zip', nil);
  finally
    HideLoadingIndicator(Self);
  end;

end;

procedure TForm33.ksNetHttpClient1ReceiveData(const Sender: TObject; AContentLength, AReadCount: Int64; var Abort: Boolean);
begin
  ksProgressBar1.MaxValue := AContentLength;
  ksProgressBar1.Value := AReadCount;
  Label1.Text := 'Bytes read: '+IntToStr(AReadCount);
end;

end.
