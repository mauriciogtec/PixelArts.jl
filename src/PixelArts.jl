module PixelArts

"""
    display_js(s::String)
# Details
Sends to display in IJulia or (to be implemented) to blink electron window in Atom
# Arguments
* `s::String` the javascript to be executed
* `require` an array of strings specifying the js libraries to use, assuming already loaded, defaults to d3
# Example
```julia
display_js("console.log('hello world');")
```
"""
function display_js(s::String, require = ["d3"])
    display("text/html",
    """
    <script>
        require(['$(join(require, "'], ['"))'],  function($(join(require, ","))) {
        $s
        });
    </script>
    """)
end
export display_js

"""
    create_canvas(id::String, vunits::Int, hunits::Int, height::Int = 250, width::Int = 250)
    create_canvas(vunits::Int, hunits::Int, height::Int = 250, width::Int = 250)

# Details
To start a canvas called "id" where the `html svg` image will be launched use

    create_canvas(vunits::Int, hunits::Int, height::Int = 250, width::Int = 250)

If `id` is not provided, then the function creates and returns a random id of the form `id = "canvas" * randstring(3)` using

    create_canvas(vunits::Int, hunits::Int, height::Int = 250, width::Int = 250)

# Arguments
* `id::String` `html` id of the `svg` tag for the canvas.
* `vunits::Int` number of vertical measurement units in the canvas
* `hunits::Int` number of horizontal measurement units in the canvas
* `height::Int` the height in display pixels of the image, the `svg` image is scalated to this height
* `width::Int` the width in display pixels of the image, the `svg` image is scalated to this width
# Examples
```julia
create_canvas("canvas", 10, 10)
canvasid = create_canvas(10, 10)
```
"""
function create_canvas(id::String, vunits::Int, hunits::Int, height::Int = 250, width::Int = 250)
    display("text/html", """
    <div class="usersvg">
    <svg id='$id' width='$(width)' height='$(height)' viewbox='0 0 $hunits $vunits'></svg>
    </div>
    <script>
    requirejs.config({paths: {d3: ["https://d3js.org/d3.v3.min.js?noext", "?$(@__DIR__)/../assets/d3.min"] }});
    </script>
    """)
end
function create_canvas(vunits::Int, hunits::Int, height::Int = 250, width::Int = 250)
    id = "canvas" * randstring(3)
    create_canvas(id, vunits, hunits, height, width)
    return id
end
export create_canvas

"""
    remove_element_by_id(id::String)
# Details
All elements created using PixelArts have unique `html` ids. This functions eliminates an id from the current canvas.
# Arguments
* `id::String` the id to be removed from the canvas (the pages's DOM)
# Examples
```julia
create_canvas("canvas", 10, 10)
remove_element_by_id("canvas")
canvasid = create_canvas(10, 10)
remove_element_by_id(canvasid)
```
"""
function remove_element_by_id(id::String)
    display("text/html", """
    <script>
    var x = document.querySelector(".usersvg #$id");
    if (!(x == null)) {
        x.parentNode.removeChild(x);
    }
    """)
end
export remove_element_by_id

"""
    add_pixels(id::String, i::Int, j::Int, colour::String = "black"; <keywords>)
    add_pixels(id::String, pos::Array{Array{Int, 1}, 1}, colour::Any = ["black"]; <keywords>)
    add_pixels(id::String, colour_array::Array; <keywords>)

# Details
Use when adding a single pixel

    add_pixels(id::String, i::Int, j::Int, colour::String = "black"; <keywords>)

# Arguments
* `id::String` the canvas id where the pixels will be added
* `i::Int` the row to place the pixel
* `j::Int` the col to place the pixel
* `colour::String` Any string representing a color interpretable by javascript (color name, rgb, hexadecimal)
* `; <keywords>` pending
# Examples
```julia
cv = create_canvas(10, 10)
add_pixels(cv, 1, 2) # added black pixels in position [1,2]
add_pixels(cv, 2, 2, "yellow")
```
"""
function add_pixels(id::String, i::Int, j::Int, colour::Any = "black"; disp = true)
    s = """
    d3.select(".usersvg #$id")
      .append("rect")
          .attr("width", "1")
          .attr("height", "1")
          .attr("transform", "translate($(j-1) $(i-1))")
          .style("fill", "$colour");
    """
    disp ? display_js(s) : return s
end
"""
# Details
Use when adding many pixels and passing an array of paris of coordiantes

    add_pixels(id::String, pos::Array{Array{Int, 1}, 1}, colour::Any = ["black"])

# Arguments
* `id::String` the canvas id where the pixels will be added
* `pos::Array{Array{Int, 1}, 1}`an array of entries `[[i1, j1], [i2,j2],...]`
* `<keywords>` dictionary of attr and style to be passed to svg elements
# Examples
```julia
cv = create_canvas(10, 10)
add_pixels(cv, [[1,2], [2, 4]]) # added black pixels in those positions
```
"""
function add_pixels(id::String, pos::Array{Array{Int, 1}, 1}; attr = Dict("fill" => "black"), style = Dict(), disp = true)
    s = """var svg = d3.select(".usersvg #$id");"""
    for p in pos
        i, j = p
        s *= """svg.append("rect").attr("width", "1").attr("height", "1").attr("transform", "translate($(j-1) $(i-1))")"""
        for key in keys(attr) s*= """.attr("$key", "$(attr[key])")""" end
        for key in keys(style) s*= """.attr("$key", "$(style[key])")""" end
        s *= ";"
    end
    disp ? display_js(s) : return s
end
"""
# Details
Use when passing a square array of colors representing the greed

    add_pixels(id::String, pos::Array{Array{Int, 1}, 1}, colour::Any = ["black"])

# Arguments
* `id::String` the canvas id where the pixels will be added
* `pos::Array{Array{Int, 1}, 1}`an array of entries `[[i1, j1], [i2,j2],...]`
* `colour::Any` An array strings of javascript interpretable colors matching the length of `pos` or with length one, in which case the same colous is used for every pixel.
# Examples
```julia
colour_array = ["green" "red";"yellow" "blue"]
cv = create_canvas(size(colour_array)...)
add_pixels(cv, colour_array) # added black pixels in those positions
```
"""
function add_pixels(id::String, colour_array::Array; disp = true)
    vunits, hunits = size(colour_array)
    pos = [[i,j] for i in 1:vunits for j in 1:hunits]
    s = ""
    for p in pos
        s *= add_pixels(id, p..., colour_array[p...]; disp = false)
    end
    display_js(s)
end
export add_pixels

"""
    render_bg(colour_array::Array, width::Int = 250, height::Int = 250)
    render_bg(array::Any, colour_dict::Dict, width::Int = 250, height::Int = 250)
# Details
Uses `create_canvas` and `add pixels` to convert a rectangular array of `html` interpretable colors in an image.

    render_bg(colour_array::Array, width::Int = 250, height::Int = 250)
# Arguments
* `colour_array::Array` an array of strings or elements that can be interpreted as html colors when converted to text
* ``height::Int`, width::Int` size in screen pixels of the image
# Value
* an id representing the created canvas
# Examples
```julia
render_bg(["green" "red";"yellow" "blue"])
```
"""
function render_bg(colour_array::Array, height::Int = 250, width::Int = 250)
    vunits, hunits = size(colour_array)
    pos = [[i,j] for i in 1:vunits for j in 1:hunits]
    colour = [colour_array[x...] for x in pos]
    new_canvas = create_canvas(vunits, hunits, height, width)
    add_pixels(new_canvas, pos, colour)
    return new_canvas
end
"""
# Details
An array of any type can be passed with a dictionary to convert the array to colors

    render_bg(array::Array, colour_dict::Dict, width::Int = 250, height::Int = 250)
# Arguments
* `array::Array` any rectangular array
* `colour_dict::Dict` a dictionary mapping the elements of render_bg to `html` interpretable colours
* ``height::Int`, width::Int` size in screen pixels of the canvas
# Value
* an id representing the created canvas
# Examples
```julia
render_bg([1 "#";3 "*"], Dict(1 => "green", "#" => "red", 3 => "yellow", "*" => "blue"))
```
"""
function render_bg(array::Array, colour_dict::Dict, width::Int = 250, height::Int = 250)
    vunits, hunits = size(array)
    pos = [[i,j] for i in 1:vunits for j in 1:hunits]
    colour = [colour_dict[array[x...]] for x in pos]
    new_canvas = create_canvas(vunits, hunits, height, width)
    add_pixels(new_canvas, pos, colour)
    return new_canvas
end
export render_bg

#function render_bg(bg_name::String, width::Int = 250, height::Int = 250)
#    if !(bg_name in ["right_turn", "circuit"])
#        error("Invalid bg_name")
#    end
#    array = readcsv(joinpath(dirname(@__FILE__), "files", "$(bg_name).csv"))
#    colour_dict = readcsv(joinpath(dirname(@__FILE__), "files", "$(bg_name)_colours.csv"))
#    colour_dict = Dict(zip(colour_dict[:,1], colour_dict[:,2]))
#    return render_bg(array, colour_dict, width, height)
#end

#function bg_colour_array(bg_name::String)
#    if !(bg_name in ["right_turn", "circuit"])
#        error("Invalid bg_name")
#    end
#    array = readcsv(joinpath(dirname(@__FILE__), "files", "$(bg_name).csv"))
#    colour_dict = readcsv(joinpath(dirname(@__FILE__), "files", "$(bg_name)_colours.csv"))
#    colour_dict = Dict(zip(colour_dict[:,1], colour_dict[:,2]))
#    vunits, hunits = size(array)
#    pos = [[i,j] for i in 1:vunits, j in 1:hunits]
#    colour_array = map(x -> colour_dict[array[x...]], pos)
#    return colour_array, pos, array
#end
#export bg_colour_array

function add_svg_element(element_id::String, canvas_id::String, element_type::String, i::Real = 1, j::Real = 1; attr = Dict(), style = Dict(), disp = true)
    # if !(element_type in ["circle", "rect", "path", "line", "image"]) error("Element type $(element_type) not supported") end
    s = """d3.select(".usersvg #$canvas_id").append("$element_type")"""
    s *= """.attr("id", "$element_id").attr("transform", "translate($(j-1) $(i-1))")"""
    for key in keys(attr) s*= """.attr("$key", "$(attr[key])")""" end
    for key in keys(style) s*= """.attr("$key", "$(style[key])")""" end
    s *= ";"
    disp ? display_js(s) : return s
end
function add_svg_element(canvas_id::String, element_type::String, i::Real = 0, j::Real = 0; attr = Dict(), style = Dict(), disp = true)
    element_id = "element" * randstring(3)
    return element_id, add_svg_element(element_id, canvas_id, element_type, i, j, attr = attr, style = style, disp = disp)
end
export add_svg_element

function set_attr(element_id::String, attr)
    s = """d3.select(".usersvg #$element_id")"""
    for key in keys(attr) s*= """.attr("$key", "$(attr[key])")""" end
    s *= ";"
    display_js(s)
end
function set_style(element_id::String, style)
    s = """d3.select(".usersvg #$element_id")"""
    for key in keys(style) s*= """.attr("$key", "$(attr[style])")""" end
    s *= ";"
    display_js(s)
end
function translate_element(element_id::String, vmove::Int, hmove::Int)
    s = """d3.select(".usersvg #$element_id").attr("transform", "translate($(hmove-1) $(vmove-1))");"""
    display_js(s)
end`
export set_attr, set_style, translate_element

function add_pixel_cross(element_id::String, canvas_id::String, i::Int, j::Int, colour::Any = "black"; disp = true)``
    attr = Dict("d" => "M0.5 0 L0.5 1 M0 0.5 L1 0.5", "transform" => "translate($(j-1) $(i-1))")
    style = Dict("stroke" => "$colour", "stroke-width" => 0.2)
    add_svg_element(element_id, canvas_id, "path", i, j, attr = attr, style = style, disp = disp)
end
function add_pixel_cross(canvas_id::String, i::Int, j::Int, colour::Any; disp = true)
    element_id = "pixel_cross" * randstring(3)
    add_pixel_cross(element_id, canvas_id, i, j, colour, disp = disp)
    return element_id
end
export add_pixel_cross

function add_pixel_arrow(element_id::String, canvas_id::String, i::Int, j::Int, rotate::Real = 0, colour::Any = "black"; disp = true)
    attr = Dict("d" => "M0 0 L0 0.5 M -0.15 0.3 L0 0.5 L0.15 0.3", "transform" => "translate($(j-0.5) $(i-0.5)) rotate($(-rotate-90))")
    style = Dict("stroke" => "$colour", "stroke-width" => 0.1)
    add_svg_element(element_id, canvas_id, "path", i, j, attr = attr, style = style, disp = disp)
end
function add_pixel_arrow(canvas_id::String, i::Int, j::Int, rotate::Real = 0, colour::Any = "black"; disp = true)
    element_id = "pixel_arrow" * randstring(3)
    add_pixel_arrow(element_id, canvas_id, i, j, rotate, colour, disp = disp)
    return element_id
end
export add_pixel_arrow

"""
    add_pixel_image(element_id::String, canvas_id::String, i::Int, j::Int, path::String; <keywords>)
    add_pixel_image(canvas_id::String, i::Int, j::Int, path::String; <keywords>)
# Details
Creates an image of unit size in a canvas.
# Arguments
* `element_id::String` the `html` id of the new image
* `canvas_id::String` the canvas in which the image will be placed
* `i::Int, j::Int` row and column to place the image of unit size
* `path` path to the image
* `<keywords>` modifiers to be passed to `add_svg_element`
# Value
If `element_id` is not passed to the function, then a random id is returned.
# Example
```julia
cv = render_bg(["green" "red";"yellow" "blue"])
add_pixel_image(cv, 1, 2, "<path>")
```
"""
function add_pixel_image(element_id::String, canvas_id::String, i::Int, j::Int, path::String; attr = Dict(), style = Dict(), disp = true)
    attr = merge(Dict(
        "xlink:href" => path,
        "x" => "0",
        "y" => "0",
        "width" => "1px",
        "height" => "1px"
    ), attr)
    add_svg_element(element_id, canvas_id, "image", i, j, attr = attr, style = style, disp = disp)
end
function add_pixel_image(canvas_id::String, i::Int, j::Int, path::String; attr = Dict(), style = Dict(), disp = true)
    element_id = "pixel_image" * randstring(3)
    add_pixel_image(element_id, canvas_id, i, j, path, attr = attr, style = style, disp = disp)
    return element_id
end
export add_pixel_image

end
