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

MyGui := MainWindow(, "PLUM")
MyGui.Show()

class MainWindow extends Gui {
    __New(options := "", title := A_ScriptName, event_obj?) {
        super.__New(options, title, event_obj?)
        this.Opt("-Resize")
        this.SetFont("s12")

        this.tab := this.AddTab3(, [ "RPPI", "Repo" ])

        this.tab.UseTab(1)
        ; vertical stacked
        {
            this.SetFont("s14")
            this.rppi_banner := this.AddText("w480", "RIME Plum Package Index")
            this.SetFont("s12")
            this.rppi_src_title := this.AddText(, "RPPI source")
            this.rppi_src := this.AddEdit("-Multi w480")
            this.rppi_src.Value := "https://raw.githubusercontent.com/rime/rppi/HEAD/index.json"
            this.rppi_schm_title := this.AddText(, "Schema")
            this.rppi_schm := this.AddTreeView("w480")
            {
                this.chinese := this.rppi_schm.Add("Chinese")
                this.jd := this.rppi_schm.Add("Jiandao", this.chinese)
            }
            ; horizonal stacked
            {
                this.rppi_fake_text := this.AddText("w400")
                this.install := this.AddButton("yp w72", "Install")
            }
        }

        this.tab.UseTab(2)
        ; vertical stacked
        {
            this.SetFont("s14")
            this.repo_banner := this.AddText("w480", "Repository")
            this.SetFont("s12")
        }

        this.tab.UseTab()
    }
}
