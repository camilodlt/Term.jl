"""
A `Pager` is a live renderable for visualizing long texts a few lines at the time. 
It shows a few lines of a longer text and allows users to move up and down the text
using keys such as arrow up and arrow down.
"""
@with_repr mutable struct Pager <: AbstractLiveDisplay
    internals::LiveInternals
    measure::Measure
    content::Vector{String}
    title::String
    tot_lines::Int
    curr_line::Int
    page_lines::Int
end


function Pager(content::String; page_lines::Int = 10, title::String = "Term.jl PAGER", width::Int=console_width(), line_numbers::Bool=false)
    page_lines = min(page_lines, console_height()-8)

    line_numbers && (content = join(map(iln -> "{dim}$(iln[1])  {/dim}" * iln[2], enumerate(split(content, "\n"))), "\n"))

    content = split(
        string(
            RenderableText(content; width=width-8)
        ), "\n")

    return Pager(
        LiveInternals(),
        Measure(page_lines+4, width),
        content,
        title,
        length(content),
        1,
        page_lines,
    )
end

# ---------------------------------- frame  ---------------------------------- #

"""
    frame(pager::Pager)::AbstractRenderable

Create a Panel with, as content, the currently visualized lines in the Pager.
"""
function frame(pager::Pager; omit_panel=false)::AbstractRenderable
    i, Δi = pager.curr_line, pager.page_lines
    page = join(pager.content[i:min(pager.tot_lines, i + Δi)], "\n")

    # make a scroll bar
    page_lines = pager.page_lines
    scrollbar_lines = 5
    scrollbar = vLine(scrollbar_lines; style="white on_white")

    p = (i+Δi/2)/pager.tot_lines
    scrollbar_center =   p * (page_lines) 
    nspaces_above = max(0, scrollbar_center-scrollbar_lines/2)|> round |> Int

    above = RenderableText(join(repeat([" \n"], nspaces_above)); style="on_gray23")
    below = RenderableText(join(repeat([" \n"], page_lines - scrollbar_lines - nspaces_above)); style="on_gray23")
    scrollbar = above / scrollbar / below

    # return content
    omit_panel && return page * scrollbar
    return Panel(
        page * scrollbar,
        fit = false,
        width = pager.measure.w,
        padding = (2, 0, 1, 1),
        subtitle = "Lines: $i:$(i+Δi) of $(pager.tot_lines)",
        subtitle_style = "bold dim",
        subtitle_justify = :right,
        style = pink,
        title = pager.title,
        title_style = "bold white",
    )
end

# --------------------------------- controls --------------------------------- #
"""
- {bold white}arrow down{/bold white}: move to the next line
"""
function key_press(p::Pager, ::ArrowDown)
    p.curr_line = min(p.tot_lines - p.page_lines, p.curr_line + 1)
end

"""
- {bold white}arrow up{/bold white}: move to the previous line
"""
function key_press(p::Pager, ::ArrowUp)
    p.curr_line = max(1, p.curr_line - 1)
end

"""
- {bold white}page down, arrow right{/bold white}: move to the next page
"""
function key_press(p::Pager, ::Union{PageDownKey,ArrowRight})
    p.curr_line = min(p.tot_lines - p.page_lines, p.curr_line + p.page_lines)
end

"""
- {bold white}page up, arrow left{/bold white}: move to the previous page
"""
function key_press(p::Pager, ::Union{PageUpKey,ArrowLeft})
    p.curr_line = max(1, p.curr_line - p.page_lines)
end

"""
- {bold white}home key{/bold white}: move to first line
"""
key_press(p::Pager, ::HomeKey) = p.curr_line = 1

"""
- {bold white}end key{/bold white}: move to the last line
"""
key_press(p::Pager, ::EndKey) = p.curr_line = p.tot_lines - p.page_lines


function key_press(p::Pager, c::CharKey)
    error()
    c.char == ']' && return key_press(p, ArrowRight())
    c.char == '[' && return key_press(p, ArrowLeft())
end