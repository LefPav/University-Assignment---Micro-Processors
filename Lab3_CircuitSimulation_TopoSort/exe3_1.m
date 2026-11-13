global SignalsTable;

# Logic Gate Functions
function s = spAND(varargin)
  temp = 1;
  for i = 1:nargin
    temp = temp * varargin{i};
  endfor
  s = temp;
endfunction

function s = spNOT(x)
  s = 1 - x;
endfunction

# Process Element
function process(element)
  global SignalsTable;

  if strcmp(element.type,'AND')
    a = SignalsTable(element.inputs(1));
    b = SignalsTable(element.inputs(2));
    SignalsTable(element.output) = spAND(a,b);

  elseif strcmp(element.type,'NOT')
    a = SignalsTable(element.inputs(1));
    SignalsTable(element.output) = spNOT(a);

  else
    printf("Unsupported element type: %s\n", element.type);
  endif

endfunction

# GiveInputs - assigns a,b,c to table
function GiveInputs(a,b,c)
  global SignalsTable;
  SignalsTable(1)=a;
  SignalsTable(2)=b;
  SignalsTable(3)=c;
endfunction

# circuitmodel
function [e_val,f_val,d_val] = circuitmodel(a,b,c)

  global SignalsTable;

  # allocate 6 signals: a,b,c,d,e,f
  SignalsTable = zeros(1,6);

  # give inputs
  GiveInputs(a,b,c);

  # --- circuit description  ---
  # E1: e = AND(a,b)   -> out = 5
  E1.type='AND'; E1.inputs=[1,2]; E1.output=5;

  # E2: f = NOT(c)     -> out = 6
  E2.type='NOT'; E2.inputs=[3];   E2.output=6;

  # E3: d = AND(e,f)   -> out = 4
  E3.type='AND'; E3.inputs=[5,6]; E3.output=4;

  # top_inputs line
  top_inputs = {"a","b","c"};

  ElementsTable = {E1,E2,E3};

  # --- simulate ---
  for i=1:length(ElementsTable)
    process(ElementsTable{i});
  endfor

  e_val = SignalsTable(5);
  f_val = SignalsTable(6);
  d_val = SignalsTable(4);

endfunction

# Switching Activity (your exact function)
function Esw = ComputeEsw(seq)
  n = length(seq);
  if n <= 1
    Esw = 0;
    return;
  endif
  sw = 0;
  for i=2:n
    if seq(i) != seq(i-1)
      sw++;
    endif
  endfor
  Esw = sw/(n-1);
endfunction


# Probabilistic propagation
# Uses p_out = AND => product(p)
#             NOT => 1 - p
function pmap = propagate_probabilities(p_a,p_b,p_c)

  # we treat signals as array indexes
  pmap = zeros(1,6);

  pmap(1)=p_a;
  pmap(2)=p_b;
  pmap(3)=p_c;

  # compute e = a AND b
  pmap(5) = pmap(1)*pmap(2);

  # compute f = NOT(c)
  pmap(6) = 1 - pmap(3);

  # compute d = e AND f
  pmap(4) = pmap(5) * pmap(6);

endfunction

function Esw_map = Esw_from_prob(pmap)
  Esw_map = zeros(1,6);
  for i=1:6
    p = pmap(i);
    Esw_map(i) = 2*p*(1-p);
  endfor
endfunction

# TESTBENCH
function testbench()

  printf("\n--- Truth Table Simulation ---\n");

  inputs = [
    0 0 0;
    0 0 1;
    0 1 0;
    0 1 1;
    1 0 0;
    1 0 1;
    1 1 0;
    1 1 1
  ];

  e_seq=[]; f_seq=[]; d_seq=[];

  for i=1:rows(inputs)
    a=inputs(i,1); b=inputs(i,2); c=inputs(i,3);
    [e,f,d] = circuitmodel(a,b,c);
    e_seq=[e_seq e];
    f_seq=[f_seq f];
    d_seq=[d_seq d];
    printf("a=%d b=%d c=%d  => e=%d f=%d d=%d\n",a,b,c,e,f,d);
  endfor

  printf("\n--- Esw from truth table ---\n");
  printf("Esw(e) = %.4f\n",ComputeEsw(e_seq));
  printf("Esw(f) = %.4f\n",ComputeEsw(f_seq));
  printf("Esw(d) = %.4f\n",ComputeEsw(d_seq));

  printf("\n--- Probabilistic (p=0.5) ---\n");
  pmap = propagate_probabilities(0.5,0.5,0.5);
  Esw_prob = Esw_from_prob(pmap);
  printf("p(d)=%.4f   Esw(d)=%.4f\n",pmap(4),Esw_prob(4));

  printf("\n--- Probabilistic (p=0.5332) ---\n");
  pmap2 = propagate_probabilities(0.5332,0.5332,0.5332);
  Esw_prob2 = Esw_from_prob(pmap2);
  printf("p(d)=%.6f   Esw(d)=%.6f\n",pmap2(4),Esw_prob2(4));

  printf("\nTestbench complete.\n\n");
endfunction

testbench();
