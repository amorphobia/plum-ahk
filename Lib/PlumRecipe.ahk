/*
 * Copyright (c) LibreService <https://github.com/LibreService/micro_plum>
 * Copyright (c) 2024, 2025 Xuesong Peng <pengxuesong.cn@gmail.com>
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

#Include <YAML>
#Include <JSON>
#Include <PlumParser>

class PlumRecipe extends Object {
    __New(loader, options?) {
        this.loader := loader
        if options and options.on_load_failure
            this.on_load_failure := options.on_load_failure
        this.loaded_files := Map()
    }

    load_file_group(file_group) {
        local errors := []
        for file in file_group {
            ; opencc?

            if this.loaded_files.Has(file)
                continue
            this.loaded_files[file] := 0
            try {
                content := this.loader.load_file(file)
            } catch Error as e {
                errors.Push({ url: file, reason: e.Message })
                continue
            }
            this.loaded_files[file] := content

            groups_to_load := []

            if SubStr(file, -5) = ".yaml" { ; case insensitive
                if SubStr(file, -12) = ".schema.yaml" {
                    try {
                        obj := YAML.parse(content)
                    } catch {
                        throw Error("Invalid " . file)
                    }
                    local new_file_groups := parse_schema(obj)
                    for new_file_group in new_file_groups {
                        mapped_new_file_group := []
                        for new_file in new_file_group {
                            if SubStr(new_file, -5) == ".json"
                                new_file := "opencc/" . new_file
                            mapped_new_file_group.Push(new_file)
                        }
                        groups_to_load.Push(mapped_new_file_group)
                    }
                } else if SubStr(file, -10) = ".dict.yaml" {
                    try {
                        obj := YAML.parse(content) ; TODO: some tables contain invalid syntax
                    } catch {
                        throw Error("Invalid " . file)
                    }
                    local new_file_groups := parse_dict(obj)
                    for new_file_group in new_file_groups {
                        groups_to_load.Push(new_file_group)
                    }
                }
            } else if SubStr(file, -5) = ".json" {
                ; parse_opencc
                try {
                    obj := JSON.parse(content)
                } catch {
                    throw Error("Invalid " . file)
                }
                local new_file_groups := parse_opencc(obj)
                for new_file_group in new_file_groups {
                    groups_to_load.Push(new_file_group)
                }
            } else if SubStr(file, -4) = ".lua" {
                ; parse_lua
            }
        }
    }
}