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

            if SubStr(file, -5) = ".yaml" { ; case insensitive
                if SubStr(file, -12) = ".schema.yaml" {
                    ; FATAL: no available yaml libraries for AutoHotkey v2!!!
                }
            }
        }
    }
}