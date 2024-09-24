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

; TODO: maybe used by other parts
expand_lua(file) {
    if RegExMatch(file, "^(lua\/.+)\.lua$", &match)
        return [ file, match[1] . "/init.lua"]
    return [ file ]
}

parse_schema(schema) {
    local result := []

    parse_include(obj) {
        for key, val in obj { ; key == index for Array
            if key == "__include" or key == "__patch" {
                local values := []
                if Type(val) = "String"
                    values := [val]
                else if Type(val) = "Array"
                    values := val
                else
                    return parse_include(val)
                for v in values {
                    if Type(v) = "String" {
                        if i := InStr(v, ":") {
                            local file := SubStr(v, 1, i - 1)
                            if SubStr(file, -5) != ".yaml"
                                file .= ".yaml"
                            result.Push(file)
                        }
                    } else if v and IsObject(v) {
                        parse_include(v)
                    }
                }
            } else if val and IsObject(val)
                parse_include(val)
        }
    }

    parse_include(schema)

    HasVal(haystack, needle) {
        if not IsObject(haystack) or haystack.Length = 0
            return 0
        for i, v in haystack
            if v == needle
                return i
        return 0
    }

    for key, val in schema {
        switch key {
            case "engine":
                for component in [ "processor", "segmentor", "translator", "filter" ] {
                    local name := component . "s"
                    if val.Has(name) {
                        local pattern := Format("^lua_{}@(\\*)?([_a-zA-Z0-9]+(/[_a-zA-Z0-9]+)*)(@[_a-zA-Z0-9]+)?$", component)
                        for item in val[name] {
                            if RegExMatch(item, pattern, &match) {
                                if match[1]
                                    result.Push(Format("lua/{}.lua", match[2]))
                                else if not HasVal(result, "rime.lua")
                                    result.Push("rime.lua")
                            }
                        }
                    }
                }
            case "translator":
                if val.Has("dictionary") {
                    local dict_yaml := val["dictionary"] . ".dict.yaml"
                    result.Push(dict_yaml)
                }
            case "punctuator":
                if val.Has("import_preset") and not HasVal(["default"], val["import_preset"])
                    result.Push(val["import_preset"] . ".yaml")
            default:
                ; 
        }
        if val and IsObject(val) and val.Has("opencc_config")
            result.Push(val["opencc_config"])
    }

    arr := []
    for i, v in result {
        arr.Push(expand_lua(v))
    }
    return arr
}
