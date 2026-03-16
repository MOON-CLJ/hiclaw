#!/bin/bash
# 代码行数统计脚本
# Usage: ./count_lines.sh

set -e

echo "=== HiClaw 代码库语言统计 ==="
echo "统计时间: $(date)"
echo ""

# Shell 脚本
sh_lines=$(find . -name "*.sh" -not -path "./.git/*" -exec cat {} \; 2>/dev/null | wc -l)
sh_files=$(find . -name "*.sh" -not -path "./.git/*" 2>/dev/null | wc -l)

# Python
py_lines=$(find . -name "*.py" -not -path "./.git/*" -exec cat {} \; 2>/dev/null | wc -l)
py_files=$(find . -name "*.py" -not -path "./.git/*" 2>/dev/null | wc -l)

# Dockerfile
df_lines=$(find . -name "Dockerfile*" -not -path "./.git/*" -exec cat {} \; 2>/dev/null | wc -l)
df_files=$(find . -name "Dockerfile*" -not -path "./.git/*" 2>/dev/null | wc -l)

# Markdown
md_lines=$(find . -name "*.md" -not -path "./.git/*" -exec cat {} \; 2>/dev/null | wc -l)
md_files=$(find . -name "*.md" -not -path "./.git/*" 2>/dev/null | wc -l)

# YAML / YML
yaml_lines=$(find . \( -name "*.yml" -o -name "*.yaml" \) -not -path "./.git/*" -exec cat {} \; 2>/dev/null | wc -l)
yaml_files=$(find . \( -name "*.yml" -o -name "*.yaml" \) -not -path "./.git/*" 2>/dev/null | wc -l)

# Makefile
make_lines=$(find . -name "Makefile" -not -path "./.git/*" -exec cat {} \; 2>/dev/null | wc -l)
make_files=$(find . -name "Makefile" -not -path "./.git/*" 2>/dev/null | wc -l)

# JSON
json_lines=$(find . -name "*.json" -not -path "./.git/*" -exec cat {} \; 2>/dev/null | wc -l)
json_files=$(find . -name "*.json" -not -path "./.git/*" 2>/dev/null | wc -l)

# TOML
toml_lines=$(find . -name "*.toml" -not -path "./.git/*" -exec cat {} \; 2>/dev/null | wc -l)
toml_files=$(find . -name "*.toml" -not -path "./.git/*" 2>/dev/null | wc -l)

# Conf
conf_lines=$(find . -name "*.conf" -not -path "./.git/*" -exec cat {} \; 2>/dev/null | wc -l)
conf_files=$(find . -name "*.conf" -not -path "./.git/*" 2>/dev/null | wc -l)

# PowerShell
ps1_lines=$(find . -name "*.ps1" -not -path "./.git/*" -exec cat {} \; 2>/dev/null | wc -l)
ps1_files=$(find . -name "*.ps1" -not -path "./.git/*" 2>/dev/null | wc -l)

# 计算总计
total_files=$((sh_files + py_files + df_files + md_files + yaml_files + make_files + json_files + toml_files + conf_files + ps1_files))
total_lines=$((sh_lines + py_lines + df_lines + md_lines + yaml_lines + make_lines + json_lines + toml_lines + conf_lines + ps1_lines))

# 输出表格
printf "%-15s %10s %12s\n" "语言" "文件数" "代码行数"
printf "%s\n" "----------------------------------------"
printf "%-15s %10s %12s\n" "Markdown" "$md_files" "$md_lines"
printf "%-15s %10s %12s\n" "Shell" "$sh_files" "$sh_lines"
printf "%-15s %10s %12s\n" "JSON" "$json_files" "$json_lines"
printf "%-15s %10s %12s\n" "Python" "$py_files" "$py_lines"
printf "%-15s %10s %12s\n" "YAML" "$yaml_files" "$yaml_lines"
printf "%-15s %10s %12s\n" "PowerShell" "$ps1_files" "$ps1_lines"
printf "%-15s %10s %12s\n" "Makefile" "$make_files" "$make_lines"
printf "%-15s %10s %12s\n" "Dockerfile" "$df_files" "$df_lines"
printf "%-15s %10s %12s\n" "Conf" "$conf_files" "$conf_lines"
printf "%-15s %10s %12s\n" "TOML" "$toml_files" "$toml_lines"
printf "%s\n" "----------------------------------------"
printf "%-15s %10s %12s\n" "总计" "$total_files" "$total_lines"

echo ""
echo "注: 统计包含空行和注释行"
