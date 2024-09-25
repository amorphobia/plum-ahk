/*
 * Copyright (c) LibreService <https://github.com/LibreService/micro_plum>
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

global builtin_opencc := [
    'HKVariants.ocd2',
    'HKVariantsRev.ocd2',
    'HKVariantsRevPhrases.ocd2',
    'JPShinjitaiCharacters.ocd2',
    'JPShinjitaiPhrases.ocd2',
    'JPVariants.ocd2',
    'JPVariantsRev.ocd2',
    'STCharacters.ocd2',
    'STPhrases.ocd2',
    'TSCharacters.ocd2',
    'TSPhrases.ocd2',
    'TWPhrases.ocd2',
    'TWPhrasesRev.ocd2',
    'TWVariants.ocd2',
    'TWVariantsRev.ocd2',
    'TWVariantsRevPhrases.ocd2',
    'hk2s.json',
    'hk2t.json',
    'jp2t.json',
    's2hk.json',
    's2t.json',
    's2tw.json',
    's2twp.json',
    't2hk.json',
    't2jp.json',
    't2s.json',
    't2tw.json',
    'tw2s.json',
    'tw2sp.json',
    'tw2t.json',
]

for i, v in builtin_opencc {
    builtin_opencc[i] := "opencc/" . v
}

global opencc_cdn := "https://cdn.jsdelivr.net/npm/@libreservice/my-opencc@0.2.0/dist/"

_match_plum(target) {
    if not RegExMatch(target, "^([-_a-zA-Z0-9]+)(\/[-_a-zA-Z0-9]+)?(@[-_a-zA-Z0-9]+)?$", &match)
        return 0
    local repo := match[2] ? (match[1] . match[2]) : "rime/" . (SubStr(match[1], 1, 5) == "rime-" ? match[1] : ("rime-" . match[1]))
    local branch := match[3] ? SubStr(match[3], 2) : ""
    return { repo: repo, branch: branch, path: "", schema: "" }
}

_match_schema(target) {
    if not RegExMatch(target, "(^https?:\/\/)?github\.com\/([-_a-zA-Z0-9]+\/[-_a-zA-Z0-9]+)\/blob\/([-_a-zA-Z0-9]+)\/(([-_a-zA-Z0-9%]+\/)*)([-_a-zA-Z0-9%]+)\.schema\.yaml$", &match) or
        not RegExMatch(target, "(^https?:\/\/)?raw\.githubusercontent\.com\/([-_a-zA-Z0-9]+\/[-_a-zA-Z0-9]+)\/([-_a-zA-Z0-9]+)\/(([-_a-zA-Z0-9%]+\/)*)([-_a-zA-Z0-9%]+)\.schema\.yaml$")
        return 0
    local repo := match[2]
    local branch := match[3] == "HEAD" ? "" : match[3]
    local path := match[4] or ""
    local schema := match[6]
    return { repo: repo, branch: branch, path: path, schema: schema }
}

normalize_target(target) {
    return _match_plum(target) || _match_schema(target)
}

fetch(url, proxy := "") {
    ; https://learn.microsoft.com/windows/win32/winhttp/winhttprequest
    whr := ComObject("WinHttp.WinHttpRequest.5.1")
    if proxy {
        whr.SetProxy(
            2, ; HTTPREQUEST_PROXYSETTING_PROXY
            proxy
        )
    }
    whr.Open("GET", url)
    whr.Send()
    whr.WaitForResponse()
    if whr.Status != 200
        throw Error(whr.Status)
    return whr.ResponseText
}

class PlumDownloader extends Object {
    ; __New(target, schema_ids := []) {
    ;     local normalized := normalize_target(target)
    ;     if not normalized
    ;         throw Error("Invalid target")
    ;     this.repo := normalized.repo
    ;     this.branch := normalized.branch
    ;     this.path := normalized.path
    ;     this.prefix := this.get_prefix()
    ;     if normalized.schema
    ;         this.schema_ids := [normalized.schema]
    ;     else
    ;         this.schema_ids := schema_ids
    ; }
    __New(repo, branch := "", path := "") {
        this.repo := repo
        this.branch := branch
        this.path := path
        this.prefix := this.get_prefix()
    }

    get_prefix := (*) => ""

    get_url(file) {
        ; TODO: opencc?
        return this.prefix . file
    }

    load_file(file) {
        local url := this.get_url(file)
        return fetch(url)
    }
}

class PlumGitHubDownloader extends PlumDownloader {
    get_prefix := (*) => Format("https://raw.githubusercontent.com/{}/{}/{}", this.repo, (this.branch or "HEAD"), this.path == "" ? "" : (SubStr(this.path, -1) == "/" ? this.path : this.path . "/"))
}

class PlumJsDelivrDownloader extends PlumDownloader {
    get_prefix := (*) => Format("https://cdn.jsdelivr.net/gh/{}{}/{}", this.repo, (this.branch ? "@" . this.branch : ""), this.path == "" ? "" : (SubStr(this.path, -1) == "/" ? this.path : this.path . "/"))
}
