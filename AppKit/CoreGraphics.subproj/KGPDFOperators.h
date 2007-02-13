/* Copyright (c) 2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */


#import <Foundation/NSObject.h>

@class KGPDFScanner,KGPDFOperatorTable;

void KGPDF_render_b(KGPDFScanner *scanner,void *info);
void KGPDF_render_B(KGPDFScanner *scanner,void *info);
void KGPDF_render_b_star(KGPDFScanner *scanner,void *info);
void KGPDF_render_B_star(KGPDFScanner *scanner,void *info);
void KGPDF_render_BDC(KGPDFScanner *scanner,void *info);
void KGPDF_render_BI(KGPDFScanner *scanner,void *info);
void KGPDF_render_BMC(KGPDFScanner *scanner,void *info);
void KGPDF_render_BT(KGPDFScanner *scanner,void *info);
void KGPDF_render_BX(KGPDFScanner *scanner,void *info);
void KGPDF_render_c(KGPDFScanner *scanner,void *info);
void KGPDF_render_cm(KGPDFScanner *scanner,void *info);
void KGPDF_render_CS(KGPDFScanner *scanner,void *info);
void KGPDF_render_cs(KGPDFScanner *scanner,void *info);
void KGPDF_render_d(KGPDFScanner *scanner,void *info);
void KGPDF_render_d0(KGPDFScanner *scanner,void *info);
void KGPDF_render_d1(KGPDFScanner *scanner,void *info);
void KGPDF_render_Do(KGPDFScanner *scanner,void *info);
void KGPDF_render_DP(KGPDFScanner *scanner,void *info);
void KGPDF_render_EI(KGPDFScanner *scanner,void *info);
void KGPDF_render_EMC(KGPDFScanner *scanner,void *info);
void KGPDF_render_ET(KGPDFScanner *scanner,void *info);
void KGPDF_render_EX(KGPDFScanner *scanner,void *info);
void KGPDF_render_f(KGPDFScanner *scanner,void *info);
void KGPDF_render_F(KGPDFScanner *scanner,void *info);
void KGPDF_render_f_star(KGPDFScanner *scanner,void *info);
void KGPDF_render_G(KGPDFScanner *scanner,void *info);
void KGPDF_render_g(KGPDFScanner *scanner,void *info);
void KGPDF_render_gs(KGPDFScanner *scanner,void *info);
void KGPDF_render_h(KGPDFScanner *scanner,void *info);
void KGPDF_render_i(KGPDFScanner *scanner,void *info);
void KGPDF_render_ID(KGPDFScanner *scanner,void *info);
void KGPDF_render_j(KGPDFScanner *scanner,void *info);
void KGPDF_render_J(KGPDFScanner *scanner,void *info);
void KGPDF_render_K(KGPDFScanner *scanner,void *info);
void KGPDF_render_k(KGPDFScanner *scanner,void *info);
void KGPDF_render_l(KGPDFScanner *scanner,void *info);
void KGPDF_render_m(KGPDFScanner *scanner,void *info);
void KGPDF_render_M(KGPDFScanner *scanner,void *info);
void KGPDF_render_MP(KGPDFScanner *scanner,void *info);
void KGPDF_render_n(KGPDFScanner *scanner,void *info);
void KGPDF_render_q(KGPDFScanner *scanner,void *info);
void KGPDF_render_Q(KGPDFScanner *scanner,void *info);
void KGPDF_render_re(KGPDFScanner *scanner,void *info);
void KGPDF_render_RG(KGPDFScanner *scanner,void *info);
void KGPDF_render_rg(KGPDFScanner *scanner,void *info);
void KGPDF_render_ri(KGPDFScanner *scanner,void *info);
void KGPDF_render_s(KGPDFScanner *scanner,void *info);
void KGPDF_render_S(KGPDFScanner *scanner,void *info);
void KGPDF_render_SC(KGPDFScanner *scanner,void *info);
void KGPDF_render_sc(KGPDFScanner *scanner,void *info);
void KGPDF_render_SCN(KGPDFScanner *scanner,void *info);
void KGPDF_render_scn(KGPDFScanner *scanner,void *info);
void KGPDF_render_sh(KGPDFScanner *scanner,void *info);
void KGPDF_render_T_star(KGPDFScanner *scanner,void *info);
void KGPDF_render_Tc(KGPDFScanner *scanner,void *info);
void KGPDF_render_Td(KGPDFScanner *scanner,void *info);
void KGPDF_render_TD(KGPDFScanner *scanner,void *info);
void KGPDF_render_Tf(KGPDFScanner *scanner,void *info);
void KGPDF_render_Tj(KGPDFScanner *scanner,void *info);
void KGPDF_render_TL(KGPDFScanner *scanner,void *info);
void KGPDF_render_Tm(KGPDFScanner *scanner,void *info);
void KGPDF_render_Tr(KGPDFScanner *scanner,void *info);
void KGPDF_render_Ts(KGPDFScanner *scanner,void *info);
void KGPDF_render_Tw(KGPDFScanner *scanner,void *info);
void KGPDF_render_Tz(KGPDFScanner *scanner,void *info);
void KGPDF_render_v(KGPDFScanner *scanner,void *info);
void KGPDF_render_w(KGPDFScanner *scanner,void *info);
void KGPDF_render_W(KGPDFScanner *scanner,void *info);
void KGPDF_render_W_star(KGPDFScanner *scanner,void *info);
void KGPDF_render_y(KGPDFScanner *scanner,void *info);
void KGPDF_render_quote(KGPDFScanner *scanner,void *info);
void KGPDF_render_dquote(KGPDFScanner *scanner,void *info);

void KGPDF_render_populateOperatorTable(KGPDFOperatorTable *table);
