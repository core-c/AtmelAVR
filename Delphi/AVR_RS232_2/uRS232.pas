unit uRS232;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TfRS232 = class(TForm)
    rgCommPort: TRadioGroup;
    rgDataBits: TRadioGroup;
    rgParity: TRadioGroup;
    rgStopBits: TRadioGroup;
    rgHandshake: TRadioGroup;
    rgBaudRate: TRadioGroup;
    gbDTR: TGroupBox;
    bSetDTR: TButton;
    bClearDTR: TButton;
    gbRTS: TGroupBox;
    bSetRTS: TButton;
    bClearRTS: TButton;
    bOpenRS232: TButton;
    Button1: TButton;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  fRS232: TfRS232;

implementation

{$R *.dfm}

end.
