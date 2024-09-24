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
#Include <PlumDownloader>

main_window := PlumMainWindow(, "Plum")
main_window.Show()

class PlumMainWindow extends Gui {
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
            this.rppi_downloader := PlumGitHubDownloader("rime/rppi")
            this.rppi_downloader.get_url("index.json")
            this.rppi_src.Value := this.rppi_downloader.get_url("index.json")
            this.rppi_schm_title := this.AddText(, "Schema")
            this.rppi_schm := this.AddTreeView("Section " . w)
            {
                ; root := this.rppi_schm.Add("All Schemas", , "Expand")
                ; this._LoadPreset()
                ; for schm in this.schemas {
                ;     this.rppi_schm.Add(schm["name"] . " " . schm["repo"], root)
                ; }
                ; this.rppi_schm.OnEvent("DoubleClick", (obj, id) => ((id !== root) ? (txt := this.rppi_schm.GetText(id), MsgBox(txt)) : 0))
                root_rppi := this._load_rppi()
                root := this.rppi_schm.Add("All Schemas", , "Expand")
                this.all_recipe_ctrl := Map()
                this._rppi_schm_add_cat_node(root_rppi.categories, root)
                this._rppi_schm_add_rcp_node(root_rppi.recipes, root)
                this.rppi_schm.OnEvent("DoubleClick", (obj, id) => ((this.all_recipe_ctrl.Has(id)) ? (txt := this.rppi_schm.GetText(id), MsgBox(txt)) : 0))
            }
        }

        this.tab.UseTab(2)
        ; vertical stacked
        {
            this.SetFont("s14")
            this.repo_banner := this.AddText(w, "Repository")
            this.SetFont("s12")
            this.repo_url_title := this.AddText(, "Repository URL")
            this.repo_url := this.AddEdit("-Multi " . w)
            this.repo_url.Value := "https://github.com/amorphobia/rime-jiandao"
            this.repo_brch_title := this.AddText(, "Branch")
            this.repo_brch := this.AddEdit("-Multi " . w)
            this.repo_brch.Value := "release"
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

    _load_rppi() {
        ; check date
        url := this.rppi_downloader.get_url("index.json")
        if not root_obj := JSON.Load(fetch(url))
            return 0

        try {
            date := root_obj["date"]
        } catch {
            return 0
        }
        date := StrReplace(date, "-") . "000000"
        if DateDiff(date, A_Now, "Days") >= 0 { ; TODO: save data instead of use A_Now
            ; root := load saved data
            return 0 ; TODO: should be loaded root
        }

        root := this._load_category(this.rppi_downloader)
        ; root.DefineProp("name", "root")
        root.name := "All Schemas"
        root.date := A_Now
        msg := JSON.Dump(root)
        MsgBox(msg)
        ; TODO: save root to file
        return root
    }

    _load_category(dl) {
        node := {
            name: "",
            categories: [],
            recipes: []
        }
        local url := dl.get_url("index.json")
        JSON.EscapeUnicode := false
        if not obj := JSON.Load(fetch(url)) {
            ; MsgBox("failed to fetch " . url)
            return node
        }
        try {
            cats := obj["categories"]
        } catch {
            cats := false
        }
        if cats && cats.Length > 0 {
            for cat in cats {
                try {
                    if !key := cat["key"]
                        continue
                    name := cat["name"]
                    ; RegExReplace(name, "\\u([0-9a-eA-E]{4})", Chr(%"0x" . "$1"%))
                } catch {
                    continue
                }
                if dl.path == "" {
                    cat_path := key
                } else if SubStr(dl.path, -1) == "/" {
                    cat_path := dl.path . key
                } else {
                    cat_path := dl.path . "/" . key
                }
                cat_dl := %Type(dl)%(dl.repo, dl.branch, cat_path)
                cat_obj := this._load_category(cat_dl)
                cat_obj.name := name
                node.categories.Push(cat_obj)
            }
        }
        try {
            rcps := obj["recipes"]
        } catch {
            rcps := false
        }
        if rcps && rcps.Length > 0 {
            for rcp in rcps {
                try {
                    if !repo := rcp["repo"]
                        continue
                    name := rcp["name"]
                    schemas := rcp["schemas"]
                } catch {
                    continue
                }
                try {
                    branch := rcp["branch"]
                } catch {
                    branch := ""
                }
                rcp_obj := {
                    repo: repo,
                    branch: branch,
                    name: name,
                    schemas: schemas
                }
                node.recipes.Push(rcp_obj)
            }
        }
        return node
    }

    _rppi_schm_add_cat_node(cat_arr, parent_ctrl) {
        for cat in cat_arr {
            cat_node_ctrl := this.rppi_schm.Add(cat.name, parent_ctrl)
            this._rppi_schm_add_cat_node(cat.categories, cat_node_ctrl)
            this._rppi_schm_add_rcp_node(cat.recipes, cat_node_ctrl)
        }
    }
    _rppi_schm_add_rcp_node(rcp_arr, parent_ctrl) {
        for rcp in rcp_arr {
            rcp_node_ctrl := this.rppi_schm.Add(rcp.name . " " . rcp.repo, parent_ctrl)
            this.all_recipe_ctrl[rcp_node_ctrl] := 1
        }
    }
}

class PlumRppiNode extends Object {
    __New(prefix, path) {
        this.prefix := prefix
        this.path := path
    }
}