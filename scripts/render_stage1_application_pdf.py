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
    regular_font = load_font(r"C:\Windows\Fonts\msyh.ttc", 22)
    section_font = load_font(r"C:\Windows\Fonts\msyhbd.ttc", 24)
    title_font = load_font(r"C:\Windows\Fonts\msyhbd.ttc", 38)

    image = Image.new("RGB", (PAGE_W, PAGE_H), "white")
    draw = ImageDraw.Draw(image)

    y = MARGIN_Y
    title = "Moon Mustache 项目申报书"
    title_w = draw.textlength(title, font=title_font)
    draw.text(((PAGE_W - title_w) / 2, y), title, font=title_font, fill="black")
    y += 72

    blocks = [
        (
            "body",
            "项目名称：Moon Mustache：Mustache 模板引擎的 MoonBit 实现\n"
            "参赛者：左嘉倩    联系方式：15929201039\n"
            "GitHub：https://github.com/bellesz0611/moon-mustache\n"
            "Gitlink：https://www.gitlink.org.cn/miemie0619/moon-mustache-mbt\n"
            "项目方向：MoonBit 模板渲染基础库 / 工程基础设施    是否为移植项目：是",
        ),
        ("section", "项目简介"),
        (
            "body",
            "Moon Mustache 计划将 Mustache 模板渲染能力引入 MoonBit 生态，为脚手架生成、代码生成、"
            "配置文件渲染、静态内容拼装、邮件模板和消息正文生成等场景提供一个轻量、稳定、可复用的模板引擎。"
            "项目面向需要在 MoonBit 中生成字符串输出、构建可复用文本模板能力的库作者、工具开发者和应用开发者。"
        ),
        ("section", "项目方向与适用场景"),
        (
            "body",
            "1. 为 CLI、脚手架或构建辅助工具生成样板代码与配置文件\n"
            "2. 为静态页面、文档片段、提示词模板或站点内容做批量渲染\n"
            "3. 为业务应用统一生成邮件、通知、消息正文等模板文本\n"
            "4. 为其他 MoonBit 库和示例工程提供可复用的模板层能力"
        ),
        ("section", "拟实现的核心功能"),
        (
            "body",
            "1. 提供 Mustache 模板的词法分析、语法解析和中间表示\n"
            "2. 支持变量插值、Section、Inverted Section、Comment、Partial、Set Delimiter 等核心语法\n"
            "3. 提供上下文栈、路径查找和值解析机制，支持常见数据结构绑定\n"
            "4. 提供 HTML escaping 与原样输出能力，覆盖常见安全需求\n"
            "5. 提供 parse_template、render_string、render_file 等基础接口\n"
            "6. 提供简单 CLI 工具、兼容性测试、README、示例和持续集成配置"
        ),
        ("section", "移植或参考说明"),
        (
            "body",
            "原项目名称：mustache.js；原项目链接：https://github.com/janl/mustache.js；"
            "参考规范：https://github.com/mustache/spec；原项目许可证：MIT License；本项目许可证：MIT License。"
        ),
        ("section", "与原项目相比的简化和重写"),
        (
            "body",
            "采用 MoonBit 原生包结构、类型系统和测试方式组织代码，而不是复刻 JavaScript 工程组织；"
            "优先实现适合 MoonBit 工程场景的核心模板能力，弱化浏览器或 Node.js 运行环境假设；"
            "以可嵌入库和命令行工具作为主要交付形式，方便接入 MoonBit CLI、脚手架和自动化流程。"
        ),
        ("section", "计划实现与最终交付"),
        (
            "body",
            "第一阶段完成仓库初始化、基础数据结构、解析器原型、最小渲染链路、示例与早期测试，并形成 10-20 次有效提交；"
            "第二阶段补全核心语法支持、Partial、文件接口、CLI、README、持续集成和回归测试；"
            "最终交付公开可复用的 MoonBit 模板渲染库、命令行工具、测试集、示例和开发文档。"
        ),
        ("section", "项目规模预估"),
        (
            "body",
            "预计主体实现约为 4k-6k 行有效 MoonBit 代码，另包含测试、示例、文档和 CI 配置，整体规模控制在赛事建议区间内。"
        ),
    ]

    for kind, text in blocks:
        if kind == "section":
            y = draw_block(draw, MARGIN_X, y, text, section_font, "black", line_gap=5, block_gap=8)
        else:
            y = draw_block(draw, MARGIN_X, y, text, regular_font, "black", line_gap=5, block_gap=9)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    image.save(OUT, "PDF", resolution=200.0)
    print(OUT)


if __name__ == "__main__":
    main()
