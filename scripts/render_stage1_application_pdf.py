from pathlib import Path

from reportlab.lib.colors import HexColor
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.cidfonts import UnicodeCIDFont
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "output" / "pdf" / "stage1_application.pdf"


def register_fonts():
    pdfmetrics.registerFont(UnicodeCIDFont("STSong-Light"))


def styles():
    base = getSampleStyleSheet()
    return {
        "title": ParagraphStyle(
            "title",
            parent=base["Title"],
            fontName="STSong-Light",
            fontSize=17,
            leading=22,
            alignment=TA_CENTER,
            textColor=HexColor("#111111"),
            spaceAfter=7,
        ),
        "heading": ParagraphStyle(
            "heading",
            parent=base["Heading2"],
            fontName="STSong-Light",
            fontSize=12,
            leading=15,
            textColor=HexColor("#111111"),
            spaceBefore=5,
            spaceAfter=3,
        ),
        "body": ParagraphStyle(
            "body",
            parent=base["BodyText"],
            fontName="STSong-Light",
            fontSize=9.1,
            leading=12.1,
            textColor=HexColor("#222222"),
            spaceAfter=2,
        ),
        "bullet": ParagraphStyle(
            "bullet",
            parent=base["BodyText"],
            fontName="STSong-Light",
            fontSize=8.9,
            leading=11.8,
            leftIndent=10,
            firstLineIndent=-7,
            bulletIndent=0,
            textColor=HexColor("#222222"),
            spaceAfter=1.5,
        ),
    }


def add_heading(story, text, style):
    story.append(Paragraph(text, style))


def add_body(story, text, style):
    story.append(Paragraph(text, style))


def add_bullet(story, text, style):
    story.append(Paragraph(text, style, bulletText="•"))


def build_story():
    s = styles()
    story = [Paragraph("Moon Mustache 项目申报书", s["title"]), Spacer(1, 2)]

    add_heading(story, "基本信息", s["heading"])
    add_body(
        story,
        "项目名称：Moon Mustache：Mustache 模板引擎的 MoonBit 实现<br/>"
        "参赛者：请在提交前填写　联系方式：请在提交前填写<br/>"
        "GitHub：https://github.com/bellesz0611/moon-mustache<br/>"
        "Gitlink：https://www.gitlink.org.cn/miemie0619/moon-mustache-mbt<br/>"
        "项目方向：MoonBit 模板渲染基础库 / 工程基础设施　是否为移植项目：是",
        s["body"],
    )

    add_heading(story, "项目简介", s["heading"])
    add_body(
        story,
        "Moon Mustache 计划将 Mustache 模板渲染能力引入 MoonBit 生态，为脚手架生成、代码生成、配置文件渲染、"
        "静态内容拼装、邮件模板和消息正文生成等场景提供一个轻量、稳定、可复用的模板引擎，面向需要在 MoonBit 中生成字符串输出、"
        "构建可复用文本模板能力的库作者、工具开发者和应用开发者。",
        s["body"],
    )
    add_body(
        story,
        "项目目标不是扩展一个功能过重的模板语言，而是优先补齐 MoonBit 生态当前缺少的基础模板能力，形成边界清楚、接口稳定、"
        "文档完整、测试可运行、可被其他项目直接复用的开源基础库。",
        s["body"],
    )

    add_heading(story, "核心功能范围", s["heading"])
    for item in [
        "提供 Mustache 模板的词法分析、语法解析和中间表示。",
        "支持变量插值、Section、Inverted Section、Comment、Partial、Set Delimiter 等核心语法。",
        "提供上下文栈、路径查找和值解析机制，支持常见数据结构绑定。",
        "提供 HTML escaping 与原样输出能力，覆盖常见安全需求。",
        "提供 parse_template、render_string、render_file、模板扫描等基础接口。",
        "提供 CLI、兼容性测试、README、示例和持续集成配置。",
    ]:
        add_bullet(story, item, s["bullet"])

    add_heading(story, "移植或参考说明", s["heading"])
    add_body(
        story,
        "原项目名称：mustache.js；原项目链接：https://github.com/janl/mustache.js；"
        "参考规范：https://github.com/mustache/spec；原项目许可证：MIT License；本项目许可证：MIT License。",
        s["body"],
    )

    add_heading(story, "与 MoonBit 生态已有同类项目的差异和新增价值", s["heading"])
    add_body(
        story,
        "MoonBit 生态中已经存在同类尝试，例如 ryota0624/mustache（mooncakes: https://mooncakes.io/docs/ryota0624/mustache；"
        "GitHub: https://github.com/ryota0624/moonbit-mustache）。本项目不是简单重复已有仓库，而是继续把模板渲染能力做成"
        "可验收、可复用、可工程化集成的基础设施。",
        s["body"],
    )
    for item in [
        "以 mustache/spec 兼容性为核心，补齐更系统的官方 fixture 对照测试与兼容报告。",
        "在基础渲染库之外提供 CLI、文件渲染、模板扫描、bundle 校验与多文件生成工作流。",
        "提供示例、持续集成、发布流程和可复用工程交付，服务其他 MoonBit 工具、脚手架和内容生成场景。",
    ]:
        add_bullet(story, item, s["bullet"])

    add_heading(story, "与原项目相比的简化和重写", s["heading"])
    add_body(
        story,
        "采用 MoonBit 原生包结构、类型系统和测试方式组织代码，而不是复刻 JavaScript 工程组织；优先实现适合 MoonBit 工程场景的"
        "核心模板能力，弱化浏览器或 Node.js 运行环境假设；以可嵌入库和命令行工具作为主要交付形式，方便接入 MoonBit CLI、"
        "脚手架和自动化流程。",
        s["body"],
    )

    add_heading(story, "计划实现与最终交付", s["heading"])
    add_body(
        story,
        "第一阶段完成仓库初始化、基础数据结构、解析器原型、最小渲染链路、示例与早期测试，并形成 10-20 次有效提交；"
        "第二阶段补全核心语法支持、Partial、文件接口、CLI、README、持续集成和回归测试；最终交付公开可复用的 MoonBit 模板"
        "渲染库、命令行工具、测试集、示例和开发文档。",
        s["body"],
    )

    add_heading(story, "项目规模预估", s["heading"])
    add_body(
        story,
        "预计主体实现约为 4k-6k 行有效 MoonBit 代码，另包含测试、示例、文档和 CI 配置，整体规模控制在赛事建议区间内。",
        s["body"],
    )

    return story


def main():
    register_fonts()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    doc = SimpleDocTemplate(
        str(OUT),
        pagesize=A4,
        leftMargin=14 * mm,
        rightMargin=14 * mm,
        topMargin=11 * mm,
        bottomMargin=11 * mm,
    )
    doc.build(build_story())
    print(OUT)


if __name__ == "__main__":
    main()
