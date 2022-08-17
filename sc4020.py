import sys
import numpy as np
from PIL import Image as im
from PIL import ImageFont as imfont
from PIL import ImageDraw as imdraw
import matplotlib.pyplot as plt
import matplotlib.image as mpimg
from bitarray import bitarray

#Docs are here: http://www.chilton-computing.org.uk/acl/pdfs/sc4020_ref_manual.pdf
#http://content-animation.org.uk/computers_and_animation/ordercode.htm

frame = 0
cursor = [100, 100]
deflector = [0, 0]
typewritter_mode = False

text_size = 16
x_size = 1024
y_size = 1024
crt = np.array([[0 for i in range(x_size)] for j in range(y_size)])

chars = [ #Using DOS font for now, but will need to reimplement with custom font set
    "0", "8", "+", "H", "-", "Q", " ", "Y",
    "1", "9", "A", "I", "J", "R", "/", "Z",
    "2", " ", "B", " ", "K", " ", "S", " ",
    "3", "=", "C", ".", "L", "$", "T", ",",
    "4", '"', "D", ")", "M", "*", "U", ")", 
    "5", "'", "E", " ", "N", " ", "V", " ", 
    "6", " ", "F", " ", "O", "~", "W", " ",
    "7", " ", "G", "?", "P", "d", "X", " "
]

canvas = im.new('RGB', [x_size + 100, y_size + 100], (0, 0, 0))
draw = imdraw.Draw(canvas)

ops = [None for i in range(90)]

def translate_coord(coord):
    return (coord[0] + 50, coord[1] + 50)

def plot_pixel(canvas, coord, val):
    canvas.putpixel(coord, (255, 255, 255))

def clear(canvas):
    draw = imdraw.Draw(canvas)
    draw.rectangle((0, 0, x_size + 100, y_size + 100), fill=(0, 0, 0, 0))

def type_char(canvas, char):
    pil_font = imfont.truetype("dos.ttf", size=text_size, encoding="unic")
    text_width, text_height = pil_font.getsize(char)

    white = "#FFFFFF"
    draw.text(translate_coord(cursor), char, font=pil_font, fill=white)

    #Advance cursor
    if cursor[0] + text_width + text_size >= x_size:
        cursor[0] = text_size
        cursor[1] += text_height
    else:
        cursor[0] += text_width

def type_char_at(canvas, coords, char):
    #pil_font = imfont.truetype("dos.ttf", size=text_size, encoding="unic")
    #text_width, text_height = pil_font.getsize(char)

    #white = "#FFFFFF"
    #draw.text(coords, char, font=pil_font, fill=white)
    global cursor
    cursor = coords
    type_char(canvas, char)

def type_string(canvas, s):
    for c in s:
        type_char(canvas, c)

def save_frame(data):
    global frame
    data = im.fromarray((crt * 255).astype(np.uint8))
    canvas.save("frames/" + "{:03d}".format(frame) + ".png")

def plot_line(canvas, v1, v2, fill="#FFFFFF"):
    draw = imdraw.Draw(canvas)
    draw.line([translate_coord(v1), translate_coord(v2)], fill=fill)

#OPERATIONS
def _advance_film(canvas, op):
    global frame, typewritter_mode
    save_frame(canvas)
    frame += 1
    typewritter_mode = False
    clear(canvas)

def _reset(canvas):
    global cursor

    cursor = [100, 100]
    _advance_film(canvas)
    #_stop_type
    #_expose_heavy

def _carriage_return(canvas):
    global cursor
    cursor[0] = text_size
    cursor[1] += text_size 

#These are all for controling modes... implement later
def _expand_image(canvas):
    True

def _reduce_image(canvas):
    True

def _stop_type(canvas, op):
    typewritter_mode = False

def _plot(canvas, op):
    type_char_at(canvas, [op['x'], op['y']], chars[op['char']])

def _type_here(canvas, op):
    global typewritter_mode
    typewritter_mode = True
    type_char_at(canvas, [op['x'], op['y']], chars[op['char']])

def _type_current_pos(canvas, op):
    global typewritter_mode
    typewritter_mode = True

    for c in ["c0", "c1", "c2", "c3", "c4"]:
        type_char(canvas, chars[op[c]])

def _draw_vector(canvas, op):
    sx = -1 if op['sx'] == 0 else 1
    sy = -1 if op['sy'] == 1 else 1

    v1 = (op['x'], op['y'])
    v2 = (op['x'] + sx * op['dx'], op['y'] + sy * op['dy'])

    print(v1, v2)

    plot_line(
        canvas,
        (op['x'], op['y']),
        (op['x'] + sx * op['dx'], op['y'] + sy * op['dy'])
    )

def _generate_x_axis(canvas, op):
    stop_bits = op['ins'][6:8] + op['ins'][18:26]
    stop = get_val(stop_bits, "raw", 0, 11)

    if stop == 0 or stop > x_size:
        stop = x_size

    plot_line(canvas, (op['x'], op['y']), (stop, op['y']))

def _generate_y_axis(canvas, op):
    stop_bits = op['ins'][6:8] + op['ins'][18:26]
    stop = get_val(stop_bits, "raw", 0, 11)

    if stop == 0 or stop > y_size:
        stop = y_size

    plot_line(canvas, (op['x'], op['y']), (op['x'], stop))

#Data parsing
bin_digits = [[0, 0, 0], [0, 0, 1], [0, 1, 0], [0, 1, 1], [1, 0, 0], [1, 0, 1], [1, 1, 0], [1, 1, 1]]

#3-bits per byte(only 0-7), so this has to be pretty custom
#   ...it's actually 3-bit binary coded octal... gross and very anti-x86
def read_ins_string(s):
    ins = bitarray()

    for d in s:
        ins.extend(bin_digits[int(d)])

    return ins

def get_val(ins, kind, start, stop):
    data = 0

    if kind == "bcd": #This seems to just be for ops
        for i in range(start, stop, 3):
            d = int("".join(list(map(lambda b: str(b), ins[i:i + 3]))), 2)
            data = (data * 10) + d
    elif kind == "char":
        data = get_val(ins, "bcd", start, stop)
        data = str(data)[::-1] #Fix endian-ness, this is just needed for char decoding?
        data = int(str(data), 8) #Oct -> dec 
    elif kind == "raw":
        d = int("".join(list(map(lambda b: str(b), ins[start:stop]))), 2) 
        data = d
    elif kind == "bin":
        data = ins[start:stop] 

    return data

def decode_ins(s):
    ins = read_ins_string(s)

    op_code = get_val(ins, "bcd", 0, 6) #Grab op code value, as int

    if op_code > len(ops):
        return None

    op = ops[op_code] #Get op structure

    if op == None:
        return None

    data = {
        "op_code": op_code,
        "handler": op["handler"],
        "ins": ins
    }

    for k in op['signature']:
        data[k] = get_val(ins, op['signature'][k][0], op['signature'][k][1], op['signature'][k][2]) #Do initial conversion
        #data[k + "_bin"] = get_val(ins, "bin", op['signature'][k][1], op['signature'][k][2]) #DEBUG! 

    return data

def run_ins(canvas, s):
    op = decode_ins(s)

    if op != None:
        print(op)
        op['handler'](canvas, op)

def run_type(canvas, s):
    global typewritter_mode

    ins = read_ins_string(s)
    op_code = get_val(ins, "bcd", 0, 6)
    op_args = get_val(ins, "raw", 7, 36)
    
    if op_code in [12, 46, 56] and op_args == 0: #This is an actual op!
        typewritter_mode = False
        run_ins(canvas, s)
        return

    for i in range(0, 36, 6):
        char = get_val(ins, "char", i, i + 6)
        print(chars[char])
        type_char(canvas, chars[char])

def run_file(canvas, path):
    global typewritter_mode
    f = open(path, 'r')

    for l in f:
        instructions = l.rstrip().split(" ")

        for ins in instructions:
            if typewritter_mode:
                run_type(canvas, ins)
            else:
                run_ins(canvas, ins)

ops[0] = {
        "name": "plot",
        "handler": _plot,
        "signature": {
            "x": ["raw", 8, 18],
            "char": ["char", 18, 23],
            "y": ["raw", 26, 36]
        }
}


ops[12] = {
    "name": "stop type",
    "handler": _stop_type,
    "signature": {}
}

ops[20] = {
        "name": "type here",
        "handler": _type_here,
        "signature": {
            "x": ["raw", 8, 18],
            "char": ["char", 18, 23],
            "y": ["raw", 26, 36]
        }
}

ops[22] =  {
    "name": "type current position",
    "handler": _type_current_pos,
    "signature": {
        "c0": ["char", 6, 12],
        "c1": ["char", 12, 18],
        "c2": ["char", 18, 24],
        "c3": ["char", 24, 30],
        "c4": ["char", 30, 36]
    }
}


ops[60] = { #Draw vector
    "name": "draw vector",
    "handler": _draw_vector,
    "signature": {
        "dx": ["raw", 2, 8],
        "x": ["raw", 8, 18],
        "sx": ["raw", 18, 19],
        "sy": ["raw", 19, 20],
        "dy": ["raw", 20, 26],
        "y": ["raw", 26, 36]
    }
}

for i in range(61, 79):
    ops[i] = ops[60]

ops[46] = {
    "name": "advance film",
    "handler": _advance_film,
    "signature": {}
}

ops[30] = {
    "name": "generate x-axis",
    "handler": _generate_x_axis,
    "signature": {
        "x": ["raw", 8, 18],
        "y": ["raw", 26, 36]
    }
}

ops[32] = {
    "name": "generate y-axis",
    "handler": _generate_y_axis,
    "signature": {
        "x": ["raw", 8, 18],
        "y": ["raw", 26, 36]
    }
}

#_driaw_vector(canvas, 100, 100, 500, 250)
#type_string(canvas, "HELLO WORLD! THIS IS A TEST OF THE SC4020 EMULATOR")

run_file(canvas, sys.argv[1])

save_frame(crt)
