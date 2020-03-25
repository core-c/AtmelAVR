unit uMain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, ExtCtrls, Odometer;

type
  TForm1 = class(TForm)
    RadioGroupBase: TRadioGroup;
    RadioGroupAni: TRadioGroup;
    ButtonInc: TButton;
    ButtonDec: TButton;
    ButtonSet: TButton;
    EditSet: TEdit;
    ScrollBar1: TScrollBar;
    Label1: TLabel;
    Bevel1: TBevel;
    Odometer1: TOdometer;
    RadioGroupDir: TRadioGroup;
    procedure RadioGroupBaseClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure RadioGroupAniClick(Sender: TObject);
    procedure ButtonIncClick(Sender: TObject);
    procedure ButtonDecClick(Sender: TObject);
    procedure ButtonSetClick(Sender: TObject);
    procedure ScrollBar1Change(Sender: TObject);
    procedure RadioGroupDirClick(Sender: TObject);
  private
  public
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

procedure TForm1.RadioGroupBaseClick(Sender: TObject);
begin
  case TRadioGroup(Sender).ItemIndex of
    0: Odometer1.BaseType := btBinary;
    1: Odometer1.BaseType := btDecimal;
    2: Odometer1.BaseType := btHexadecimal;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  RadioGroupBase.ItemIndex := 1;
  RadioGroupAni.ItemIndex := 2;
  RadioGroupDir.ItemIndex := 1;
  ScrollBar1.Position := Odometer1.FrameInterval;
end;

procedure TForm1.RadioGroupAniClick(Sender: TObject);
begin
  case TRadioGroup(Sender).ItemIndex of
    0: Odometer1.AnimationType := atNone;
    1: Odometer1.AnimationType := atSynchronous;
    2: Odometer1.AnimationType := atAsynchronous;
  end;
end;

procedure TForm1.ButtonIncClick(Sender: TObject);
begin
  Odometer1.Increase;
end;

procedure TForm1.ButtonDecClick(Sender: TObject);
begin
  Odometer1.Decrease;
end;

procedure TForm1.ButtonSetClick(Sender: TObject);
begin
  Odometer1.Value := StrToInt(EditSet.Text);
end;

procedure TForm1.ScrollBar1Change(Sender: TObject);
begin
  Odometer1.FrameInterval := TScrollBar(Sender).Position;
end;

procedure TForm1.RadioGroupDirClick(Sender: TObject);
begin
  case TRadioGroup(Sender).ItemIndex of
    0: Odometer1.IncTopToBottom := True;
    1: Odometer1.IncTopToBottom := False;
  end;
end;

end.
