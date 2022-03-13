"""
conjectured way of Pacogen LUT's generation with N addresses and M sized outputs.

python pacogen_mant_recip_LUT_gen.py -i 8 -o 9 > lut.sv
"""

import argparse
from fixed2float import Fx, to_Fx

parser = argparse.ArgumentParser(description="Generate LUT")

parser.add_argument("--size-in", "-i", type=int, required=True, help="Input width")
parser.add_argument("--size-out", "-o", type=int, required=True, help="Output width")

args = parser.parse_args()
LUT_IN = args.size_in
LUT_OUT = args.size_out


lut = dict()

def compute_frac_recip_val(frac):
    """
    frac_val:  .ffffff
    
    ans: .ffff
    """
    if frac == 0:
        return 0

    fx_mant = Fx(frac | (1 << LUT_IN), 1, LUT_IN + 1)
    
    fx_mant_only_fractional = to_Fx(fx_mant.eval() - 1.0, 0, LUT_IN, round=True)

    fx_mant_recip = to_Fx(1.0 / fx_mant.eval(), 0, 0 + LUT_OUT, round=True)
    
    lut[fx_mant_only_fractional.val] = fx_mant_recip.val
    return fx_mant_recip.val


SPACES = "\t" * 3
lut_content = ""
for frac in range(0, 1 << LUT_IN):
    lut_content += f"{SPACES}{LUT_IN}'d{frac} :    dout <= {LUT_OUT}'h{hex(compute_frac_recip_val(frac)).replace('0x','')};\n"


print(
    """/* autogenerated by $PPU_ROOT/scripts/pacogen_mant_recip_LUT_gen.py */

module lut #(
        parameter LUT_WIDTH_IN = {},
        parameter LUT_WIDTH_OUT = {}
    )(
        input   [(LUT_WIDTH_IN)-1:0]    addr,
        output  [(LUT_WIDTH_OUT)-1:0]   out
    );

    reg [(LUT_WIDTH_OUT)-1:0] dout;
    reg [(LUT_WIDTH_OUT)-1:0] mant_recip_rom [(2**LUT_WIDTH_IN - 1):0];

    always @(*) begin
        case (addr)
{}
            default: dout <= 'h0;
        endcase
    end

    assign out = dout; // << 1;
endmodule



""".format(
        LUT_IN,
        LUT_OUT,
        lut_content,
    )
)
