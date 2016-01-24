{
  Copyright (C) 2013-2016 Tim Sinaeve tim.sinaeve@gmail.com

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
}

unit Demo.DDuce.Editor;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.Menus,
  Vcl.ComCtrls,

  DDuce.Editor.Interfaces;

type
  TfrmEditor = class(TForm)
    sbrMain     : TStatusBar;
    pnlLeft     : TPanel;
    pnlRight    : TPanel;
    splVertical : TSplitter;

  private
    FEditor  : IEditorView;
    FManager : IEditorManager;
    FMainToolbar      : TToolbar;
    FSelectionToolbar : TToolbar;
    FRightToolbar     : TToolbar;
    FMainMenu         : TMainMenu;

  public
    procedure AfterConstruction; override;


  end;

implementation

uses
  DDuce.Editor.Factories;

{$R *.dfm}

{ TfrmEditor }

procedure TfrmEditor.AfterConstruction;
begin
  inherited AfterConstruction;
  FManager := TEditorFactories.CreateManager(Self);
  FEditor  := TEditorFactories.CreateView(pnlRight, FManager);
  FMainMenu := TEditorFactories.CreateMainMenu(Self, FManager.Actions, FManager.Menus);
  FMainToolbar := TEditorFactories.CreateMainToolbar(
    Self,
    pnlRight,
    FManager.Actions,
    FManager.Menus
  );
  FSelectionToolbar := TEditorFactories.CreateSelectionToolbar(
    Self,
    pnlRight,
    FManager.Actions,
    FManager.Menus
  );
end;

end.
