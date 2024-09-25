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
main_window.Build()

class PlumMainWindow extends Gui {
    __New(options := "", title := A_ScriptName, event_obj?) {
        super.__New(options, title, event_obj?)
        this.Opt("-Resize")
        this.SetFont("s12", "Microsoft YaHei UI")
        this.Title := "东风破"

        this.tab := this.AddTab3(, [ "索引", "仓库" ])

        static w := "w480"
        this.tab.UseTab(1)
        ; vertical stacked
        {
            this.SetFont("s14")
            this.rppi_banner := this.AddText(w, "中州韵输入法之东风破配方索引 (RPPI)")
            this.SetFont("s12")
            this.rppi_src_title := this.AddText("Section", "RPPI 源地址")
            ; horizontal stacked
            {
                this.rppi_src := this.AddEdit("-Multi w396")
                this.rppi_downloader := PlumGitHubDownloader("rime/rppi")
                this.rppi_src.Value := this.rppi_downloader.get_url("index.json")

                this.rppi_src_load := this.AddButton("yp w76 hp", "载入")
                this.rppi_src_load.OnEvent("Click", (*) => this._build_rppi_tree_view())
            }
            this.rppi_schm_title := this.AddText("xs y+m", "方案")
            this.rppi_schm := this.AddTreeView("Section " . w)
            this.rppi_schm.OnEvent("DoubleClick", (*) => this._install())
        }

        this.tab.UseTab(2)
        ; vertical stacked
        {
            this.SetFont("s14")
            this.repo_banner := this.AddText(w, "配方仓库")
            this.SetFont("s12")
            this.repo_url_title := this.AddText(, "仓库链接")
            this.repo_url := this.AddEdit("-Multi " . w)
            this.repo_url.Value := "https://github.com/amorphobia/rime-jiandao"
            this.repo_url.OnEvent("Change", (*) => this.repo_brch.Value := "")
            this.repo_brch_title := this.AddText(, "分支")
            this.repo_brch := this.AddEdit("-Multi " . w)
            this.repo_brch.Value := "release"
        }

        this.tab.UseTab()
        ; vertical stacked
        {
            this.SetFont("s14")
            this.rime_path_title := this.AddText("xs y+m", "Rime 用户文件夹")
            this.SetFont("s12")
            ; horizontal stacked
            {
                this.rime_path := this.AddEdit("-Multi w396")
                this.rime_path.Value := A_AppData . "\Rime"

                this.rime_path_sel := this.AddButton("yp w76 hp", "选择")
                this.rime_path_sel.OnEvent("Click", (*) => (val := FileSelect("D2", DirExist(this.rime_path.Value) ? this.rime_path.Value : (A_AppData . "\Rime"), "选择 Rime 用户文件夹"), val ? this.rime_path.Value := val : 0))
            }
            this.AddText("xs y+m Section", "网络代理")
            this.proxy := this.AddEdit("ys -Multi w400")
            ; horizonal stacked
            {
                this.fake_text := this.AddText("w316")
                this.install := this.AddButton("Default yp w76 h28", "安装")
                this.install.OnEvent("Click", (*) => this._install())
            }
        }
    }

    Build() {
        this._build_rppi_tree_view(true)
    }

    _build_rppi_tree_view(load_preset := false) {
        this.rppi_schm.Delete()
        root_rppi := this._load_rppi(load_preset)
        root := this.rppi_schm.Add(root_rppi["name"], , "Expand")
        this.all_recipe_ctrl := Map()
        this._rppi_schm_add_cat_node(root_rppi["categories"], root)
        this._rppi_schm_add_rcp_node(root_rppi["recipes"], root)
    }

    _load_rppi(load_preset := false) {
        url := this.rppi_downloader.get_url("index.json")
        if not root_obj := JSON.Load(fetch(url, this.proxy.Value))
            return 0

        try {
            date := root_obj["date"]
        } catch {
            return 0
        }
        date := StrReplace(date, "-") . "000000"
        old_date := "19700101000000"
        if FileExist("index.json") {
            index := FileRead("index.json", "UTF-8")
            index_obj := JSON.Load(index)
            if index_obj && index_obj.Has("date")
                old_date := index_obj["date"]
            if load_preset || DateDiff(date, old_date, "Days") < 0 {
                return index_obj
            }
        }

        root := this._load_category(this.rppi_downloader)
        root.name := "所有方案"
        root.date := A_Now
        msg := JSON.Dump(root)
        try {
            FileDelete("index.json")
        }
        FileAppend(msg, "index.json", "UTF-8-RAW")
        return JSON.Load(msg)
    }

    _load_category(dl) {
        node := {
            name: "",
            categories: [],
            recipes: []
        }
        local url := dl.get_url("index.json")
        JSON.EscapeUnicode := false
        if not obj := JSON.Load(fetch(url, this.proxy.Value)) {
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
                try {
                    dependencies := rcp["dependencies"]
                } catch {
                    dependencies := []
                }
                try {
                    reverseDependencies := rcp["reverseDependencies"]
                } catch {
                    reverseDependencies := []
                }
                rcp_obj := {
                    repo: repo,
                    branch: branch,
                    name: name,
                    schemas: schemas,
                    dependencies: dependencies,
                    reverseDependencies: reverseDependencies
                }
                node.recipes.Push(rcp_obj)
            }
        }
        return node
    }

    _rppi_schm_add_cat_node(cat_arr, parent_ctrl) {
        for cat in cat_arr {
            cat_node_ctrl := this.rppi_schm.Add(cat["name"], parent_ctrl)
            this._rppi_schm_add_cat_node(cat["categories"], cat_node_ctrl)
            this._rppi_schm_add_rcp_node(cat["recipes"], cat_node_ctrl)
        }
    }
    _rppi_schm_add_rcp_node(rcp_arr, parent_ctrl) {
        for rcp in rcp_arr {
            rcp_node_ctrl := this.rppi_schm.Add(rcp["name"] . " " . rcp["repo"], parent_ctrl)
            this.all_recipe_ctrl[rcp_node_ctrl] := {
                name: rcp["name"],
                repo: rcp["repo"],
                branch: rcp["branch"],
                schemas: rcp["schemas"],
                dependencies: rcp["dependencies"],
                reverseDependencies: rcp["reverseDependencies"]
            }
        }
    }

    _install() {
        tab_id := this.tab.Value
        if tab_id == 1 {
            id := this.rppi_schm.GetSelection()
            if !this.all_recipe_ctrl.Has(id)
                return
            msg := this.all_recipe_ctrl[id].name . ": " . this.all_recipe_ctrl[id].repo
            if this.all_recipe_ctrl[id].branch
                msg := msg . "@" . this.all_recipe_ctrl[id].branch
            MsgBox(msg)
            if not path := this.rime_path.Value {
                MsgBox("未设置 Rime 用户文件夹")
                return
            }
            if !DirExist(path) {
                if "Yes" != MsgBox("Rime 用户文件夹不存在，是否创建？", , "YesNo") {
                    return
                }
                try {
                    DirCreate(path)
                } catch {
                    MsgBox("创建 Rime 用户文件夹失败")
                }
            }
        }
    }
}

class PlumRppiNode extends Object {
    __New(prefix, path) {
        this.prefix := prefix
        this.path := path
    }
}