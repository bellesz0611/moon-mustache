from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "output" / "pdf" / "stage1_application.pdf"

PAGE_W = 1654
PAGE_H = 2339
MARGIN_X = 120
MARGIN_Y = 110
CONTENT_W = PAGE_W - 2 * MARGIN_X


def load_font(path: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(path, size=size)


def wrap_text(draw: ImageDraw.ImageDraw, text: str, font: ImageFont.FreeTypeFont, width: int):
    lines = []
    for raw_paragraph in text.split("\n"):
        if not raw_paragraph:
            lines.append("")
            continue
        current = ""
        for ch in raw_paragraph:
            candidate = current + ch
            if draw.textlength(candidate, font=font) <= width:
                current = candidate
            else:
                if current:
                    lines.append(current)
                current = ch
        if current:
            lines.append(current)
    return lines


def draw_block(draw, x, y, text, font, fill, line_gap, block_gap):
    lines = wrap_text(draw, text, font, CONTENT_W)
    for line in lines:
        draw.text((x, y), line, font=font, fill=fill)
        y += font.size + line_gap
    return y + block_gap


def main():
    regular_font = load_font(r"C:\Windows\Fonts\msyh.ttc", 25)
    section_font = load_font(r"C:\Windows\Fonts\msyhbd.ttc", 29)
    title_font = load_font(r"C:\Windows\Fonts\msyhbd.ttc", 42)

    image = Image.new("RGB", (PAGE_W, PAGE_H), "white")
    draw = ImageDraw.Draw(image)

    y = MARGIN_Y
    title = "Moon Mustache 项目申报书"
    title_w = draw.textlength(title, font=title_font)
    draw.text(((PAGE_W - title_w) / 2, y), title, font=title_font, fill="black")
    y += 86

    blocks = [
        (
            "body",
            "项目名称：Moon Mustache：MoonBit 的 Mustache 模板渲染引擎\n"
            "参赛者：[填写姓名]    联系方式：[填写手机号 / 邮箱]\n"
            "GitHub：[填写 GitHub 仓库链接]\n"
            "Gitlink：[填写 Gitlink 仓库链接]\n"
            "项目方向：MoonBit 模板渲染基础库 / 工程基础设施\n"
            "是否为移植项目：是（参考成熟项目并进行 MoonBit 化重写）",
        ),
        ("section", "项目简介"),
        (
            "body",
            "Moon Mustache 计划将 Mustache 模板渲染能力系统化引入 MoonBit 生态，"
            "为脚手架、代码生成、配置生成、静态页面、邮件 / 消息模板等场景提供轻量、稳定、可嵌入的模板引擎。"
            "项目面向 MoonBit 工具开发者、库作者和应用开发者，提供模板解析、上下文绑定、渲染执行、"
            "Partial 组合、文件输入输出及命令行接口，并通过对照 Mustache 规范测试集提升兼容性与可迁移性。"
        ),
        ("section", "适用场景"),
        (
            "body",
            "1. MoonBit CLI 或构建工具中的代码与配置生成\n"
            "2. 静态页面、文档片段、提示词模板的批量渲染\n"
            "3. 应用中的邮件、通知、消息正文模板生成\n"
            "4. 其他 MoonBit 库或框架的可复用模板能力底座"
        ),
        ("section", "核心功能"),
        (
            "body",
            "1. 提供 Mustache 模板的词法分析、语法解析与抽象表示\n"
            "2. 支持变量插值、Section、Inverted Section、Comment、Partial、Set Delimiter 等核心语法\n"
            "3. 提供上下文栈与路径查找机制，支持常见数据结构绑定\n"
            "4. 提供安全 HTML escaping 与原样输出能力\n"
            "5. 提供库接口，如 render_string、render_file、parse_template，以及简单 CLI 工具\n"
            "6. 提供规范兼容测试、示例、README 与持续集成配置"
        ),
        ("section", "移植与新增价值"),
        (
            "body",
            "主要参考项目：mustache.js（MIT License），并对照 mustache/spec 进行兼容实现。"
            "本项目不会直接复刻 JavaScript 工程形态，而是采用 MoonBit 原生包结构、类型系统、错误处理与测试方式重写；"
            "以可嵌入库 + CLI 工具为主要交付形式，优先保证接口清晰、便于二次集成，并通过规范测试、示例项目和迁移说明降低接入门槛。"
        ),
        ("section", "计划与交付"),
        (
            "body",
            "第一阶段完成仓库初始化、基础 API 设计、解析器原型、示例与早期测试，形成 10-20 次有效提交；"
            "第二阶段补全核心语法支持、上下文解析、渲染流程、CLI 工具、README、CI 与回归测试。"
            "最终交付可公开复用的 MoonBit 模板渲染库、配套命令行工具、完整文档与测试。"
        ),
        ("section", "项目规模预估"),
        ("body", "预计为 4k-6k 行有效 MoonBit 代码，另包含测试、示例、文档与 CI 配置。"),
    ]

    for kind, text in blocks:
        if kind == "section":
            y = draw_block(draw, MARGIN_X, y, text, section_font, "black", line_gap=8, block_gap=10)
        else:
            y = draw_block(draw, MARGIN_X, y, text, regular_font, "black", line_gap=8, block_gap=12)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    image.save(OUT, "PDF", resolution=200.0)
    print(OUT)


if __name__ == "__main__":
    main()
