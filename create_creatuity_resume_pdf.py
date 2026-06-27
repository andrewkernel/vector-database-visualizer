from reportlab.lib.pagesizes import letter
from reportlab.lib.utils import simpleSplit
from reportlab.pdfgen import canvas


OUTPUT_PATH = r"C:\Users\flamj\OneDrive\Documents\New project\Andrew_Dang_Creatuity_Resume.pdf"
PAGE_WIDTH, PAGE_HEIGHT = letter

LEFT = 46.8
RIGHT = 570.6
BODY_WIDTH = RIGHT - LEFT


def draw_centered(c, text, y, font_name, font_size):
    c.setFont(font_name, font_size)
    c.drawCentredString(PAGE_WIDTH / 2, y, text)


def draw_right(c, text, y, font_name, font_size):
    c.setFont(font_name, font_size)
    c.drawRightString(RIGHT, y, text)


def draw_left(c, text, y, font_name, font_size, x=LEFT):
    c.setFont(font_name, font_size)
    c.drawString(x, y, text)


def wrapped_lines(text, font_name, font_size, width):
    return simpleSplit(text, font_name, font_size, width)


def draw_bullet(c, text, y, width=460, indent=22.5, bullet_x=59.1):
    draw_left(c, "-", y, "Times-Roman", 11, bullet_x)
    lines = wrapped_lines(text, "Times-Roman", 11, width)
    for index, line in enumerate(lines):
        draw_left(c, line, y - index * 13.2, "Times-Roman", 11, LEFT + indent)
    return y - len(lines) * 13.2


def section(c, title, y):
    draw_left(c, title, y, "Times-Roman", 18, 36)
    c.line(36, y - 4, PAGE_WIDTH - 36, y - 4)
    return y - 20


def entry_header(c, left_text, right_text, y):
    draw_left(c, left_text, y, "Times-Bold", 14)
    draw_right(c, right_text, y, "Times-Roman", 14)
    return y - 13.5


def entry_subheader(c, left_text, right_text, y):
    draw_left(c, left_text, y, "Times-Italic", 11.8)
    draw_right(c, right_text, y, "Times-Italic", 11.8)
    return y - 10.8


def main():
    c = canvas.Canvas(OUTPUT_PATH, pagesize=letter)
    c.setTitle("Andrew Dang - Creatuity Resume")

    # Name and contact
    draw_centered(c, "Andrew Dang", 734, "Times-Bold", 31)
    draw_centered(
        c,
        "(682) 300-1386 | andrewdangbusiness@gmail.com | LinkedIn | GitHub | Portfolio",
        704,
        "Times-Roman",
        11,
    )

    y = 641

    # Education
    y = section(c, "Education", y)
    y = entry_header(c, "University of Texas at Arlington", "Arlington, TX", y)
    y = entry_subheader(c, "B.S. in Computer Science, Minor in Business", "Expected May 2028", y)
    edu_text = "GPA: 3.84/4.0 | Coursework: Data Structures and Algorithms, Object-Oriented Programming, Databases, Discrete Structures."
    draw_left(c, "-", y, "Times-Roman", 11, 59.1)
    edu_lines = wrapped_lines(edu_text, "Times-Roman", 11, 470)
    for i, line in enumerate(edu_lines):
        draw_left(c, line, y - i * 13, "Times-Roman", 11, 70.8)
    y = y - len(edu_lines) * 13 - 14

    # Experience
    y = section(c, "Experience", y)

    y = entry_header(c, "Visionet Systems", "Cranbury, NJ", y)
    y = entry_subheader(c, "IT Software Engineer Intern", "June 2026 - Present", y)
    y = draw_bullet(
        c,
        "Support production software engineering work under a senior engineer, including debugging workflows, code reviews, issue investigation, and practical fixes across an existing codebase.",
        y,
    )
    y -= 1.5

    y = entry_header(c, "Premier Soccer Services", "Katy, TX", y)
    y = entry_subheader(c, "Software Engineer Intern", "September 2025 - May 2026", y)
    y = draw_bullet(
        c,
        "Built a production tournament bracket system with Python, Flask, PostgreSQL, and Pandas for 200+ teams, automating match generation, score tracking, standings, and outcome analysis.",
        y,
    )
    y = draw_bullet(
        c,
        "Developed a workforce coordination dashboard with React, TypeScript, Tailwind CSS, and Supabase to manage 50+ workers, assignments, lodging, and event logistics.",
        y,
    )
    y -= 1.5

    y = entry_header(c, "TLT - Tomorrow's Leaders Today", "Richardson, TX", y)
    y = entry_subheader(c, "Software Engineer Intern", "May 2025 - Aug 2026", y)
    y = draw_bullet(
        c,
        "Engineered a full-stack grant discovery platform with Next.js, Tailwind CSS, SQLite, and Prisma, helping nonprofit users search funding opportunities and simplify application planning.",
        y,
    )
    y = draw_bullet(
        c,
        "Translated stakeholder requirements from recurring meetings into wireframes, UI flows, and implementation tasks aligned with client goals and delivery deadlines.",
        y,
    )
    y -= 1.5

    # Projects
    y = section(c, "Projects", y)

    project_line_1 = "Peak | Next.js, React, TypeScript, Supabase, Electron"
    draw_left(c, project_line_1, y, "Times-Bold", 12.7)
    draw_right(c, "GitHub", y, "Times-Roman", 12.7)
    y -= 13.5
    y = draw_bullet(
        c,
        "Built and deployed a full-stack service platform supporting 100+ paid clients and a 600+ member Discord community, combining booking, admin workflows, and software delivery.",
        y,
    )
    y = draw_bullet(
        c,
        "Managed customer-facing service features and software delivery workflows with an emphasis on communication, reliability, and usability.",
        y,
    )
    y -= 1.5

    project_line_2 = "Open Source Contributions | Next.js, Playwright, GitHub Actions, Python"
    draw_left(c, project_line_2, y, "Times-Bold", 12.7)
    draw_right(c, "PR", y, "Times-Roman", 12.7)
    y -= 13.5
    y = draw_bullet(
        c,
        "Opened multiple third-party PRs that fixed bugs, improved automated checks, and tested scoring, export, date parsing, and link handling behavior in existing codebases.",
        y,
    )
    y -= 1.5

    # Technical Skills
    y = section(c, "Technical Skills", y)
    skills = [
        ("Languages & Tools:", "JavaScript, TypeScript, Python, Java, C++, C#, SQL, Git, GitHub, Postman, Linux, VS Code"),
        ("Web:", "HTML, CSS, React, Next.js, Flask, REST APIs, Tailwind CSS"),
        ("Databases & Storage:", "PostgreSQL, MySQL, SQLite, Supabase, MongoDB"),
        ("Additional Strengths:", "Clear written and spoken communication, translating client requests into technical tasks, stakeholder collaboration, and user-friendly technical explanations"),
    ]

    for label, value in skills:
        draw_left(c, label, y, "Times-Bold", 11)
        label_width = c.stringWidth(label, "Times-Bold", 11)
        lines = wrapped_lines(value, "Times-Roman", 11, BODY_WIDTH - label_width - 6)
        for i, line in enumerate(lines):
            draw_left(c, line, y - i * 12.5, "Times-Roman", 11, LEFT + label_width + 6)
        y -= max(1, len(lines)) * 12.5

    c.save()


if __name__ == "__main__":
    main()
