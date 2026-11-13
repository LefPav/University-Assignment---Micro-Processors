function s=signalprobsN(varargin)

  spAND(varargin{:})
  spOR(varargin{:})
  spXOR(varargin{:})
  spNAND(varargin{:})
  spNOR(varargin{:})
end

function s = spAND(varargin)
  printf("AND Gate for input probabilities: \n", length(varargin))
  s = 1;
  for i = 1:length(varargin)
   s = s * varargin{i};
  endfor
endfunction

function s = spOR(varargin)
  printf("OR Gate for input probabilities: \n", length(varargin))
  s = 1;
  for i = 1:length(varargin)
   s = s * (1 - varargin{i});
  endfor
  s = 1 - s;
endfunction

function s = spXOR(varargin)
  printf("XOR Gate for input probabilities: \n", length(varargin))
  s = 1;
  for i = 1:length(varargin)
   s = s * (1 - 2*varargin{i});
  endfor
  s = 1 - s;
  s = s/2;
endfunction

function s = spNAND(varargin)
  printf("NAND Gate for input probabilities: \n", length(varargin))
  s = 1;
  for i = 1:length(varargin)
   s = s * varargin{i};
  endfor
  s = 1-s;
endfunction

function s = spNOR(varargin)
  printf("NOR Gate for input probabilities: \n", length(varargin))
  s = 1;
  for i = 1:length(varargin)
   s = s * (1 - varargin{i});
  endfor
endfunction
