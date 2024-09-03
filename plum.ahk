/*
 * Copyright (c) 2024 Xuesong Peng <pengxuesong.cn@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#Requires AutoHotkey v2.0
#Include <JSON>

MyGui := MainWindow(, "PLUM")
MyGui.Show()

class MainWindow extends Gui {
    __New(options := "", title := A_ScriptName, event_obj?) {
        super.__New(options, title, event_obj?)
        this.Opt("-Resize")
        this.SetFont("s12")

        this.tab := this.AddTab3(, [ "RPPI", "Repo" ])

        static w := "w480"
        this.tab.UseTab(1)
        ; vertical stacked
        {
            this.SetFont("s14")
            this.rppi_banner := this.AddText(w, "RIME Plum Package Index")
            this.SetFont("s12")
            this.rppi_src_title := this.AddText(, "RPPI source")
            this.rppi_src := this.AddEdit("-Multi " . w)
            this.rppi_src.Value := "https://raw.githubusercontent.com/rime/rppi/HEAD/index.json"
            this.rppi_schm_title := this.AddText(, "Schema")
            this.rppi_schm := this.AddTreeView("Section " . w)
            {
                root := this.rppi_schm.Add("All Schemas", , "Expand")
                this._LoadPreset()
                for schm in this.schemas {
                    this.rppi_schm.Add(schm["name"] . " " . schm["repo"], root)
                }
                this.rppi_schm.OnEvent("DoubleClick", (obj, id) => ((id !== root) ? (txt := this.rppi_schm.GetText(id), MsgBox(txt)) : 0))
            }
        }

        this.tab.UseTab(2)
        ; vertical stacked
        {
            this.SetFont("s14")
            this.repo_banner := this.AddText("xm+20 " . w, "Repository")
            this.SetFont("s12")
        }

        this.tab.UseTab()
        ; vertical stacked
        {
            this.SetFont("s14")
            this.rime_path_title := this.AddText("xs y+m", "Rime user folder")
            this.SetFont("s12")
            this.rime_path := this.AddEdit("-Multi " . w)
            this.rime_path.Value := A_AppData . "\Rime"
            ; horizonal stacked
            {
                this.fake_text := this.AddText("w396")
                this.install := this.AddButton("Default yp w76", "Install")
                this.install.OnEvent("Click", (obj*) => MsgBox("Installing..."))
            }
        }
    }

    _LoadPreset() {
        str := FileOpen("index.json", "r", "UTF-8").Read()
        obj := JSON.Load(str)
        if not obj or not obj["recipes"] or not obj["recipes"].Length
            this.schemas := {}
        this.schemas := obj["recipes"]
    }
}
