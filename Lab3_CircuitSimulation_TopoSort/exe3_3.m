global SignalsTable;

% Primitive gate helpers
function s = spAND(varargin)
  temp = 1;
  for i = 1:nargin, temp*=varargin{i}; endfor
  s = temp;
endfunction

function s = spNOT(x)
  s = 1 - x;
endfunction

% process(element)
function process(element)
  global SignalsTable;
  t = upper(element.type);
  vals = SignalsTable(element.inputs);
  if strcmp(t,'AND')
    SignalsTable(element.output) = spAND(vals(1),vals(2));
  elseif strcmp(t,'NOT')
    SignalsTable(element.output) = spNOT(vals(1));
  else
    printf("Unsupported element: %s\n", t);
  endif
endfunction

% ComputeEsw (same as before)
function Esw = ComputeEsw(seq)
  n = length(seq);
  if n<=1, Esw=0; return; endif
  sw=0;
  for i=2:n
    if seq(i)!=seq(i-1), sw++; endif
  endfor
  Esw = sw/(n-1);
endfunction

% PARSER (
function [Elems, signals_names, declared_top_inputs] = parse_circuit_file(filename)
  fid=fopen(filename,'r'); if fid<0, error(['Cannot open ',filename]); endif
  Elems={}; signals={}; declared_top_inputs={};
  while true
    L=fgetl(fid); if ~ischar(L), break; endif
    L=strtrim(L); if isempty(L), continue; endif
    if startsWith(L,'//')||startsWith(L,'#'), continue; endif

    T=strsplit(L);
    if strcmpi(T{1},'top_inputs')
      declared_top_inputs = T(2:end);
      for k=1:numel(declared_top_inputs), signals{end+1}=declared_top_inputs{k}; endfor
      continue
    endif

    gate=upper(T{1});
    out=T{2};
    ins=T(3:end);

    E.type=gate; E.output_name=out; E.input_names=ins;
    Elems{end+1}=E;

    signals{end+1}=out;
    for k=1:numel(ins), signals{end+1}=ins{k}; endfor
  endwhile
  fclose(fid);

  % unique preserve order
  sig_unique={};
  for i=1:numel(signals)
    s=signals{i};
    if ~any(strcmp(sig_unique,s)), sig_unique{end+1}=s; endif
  endfor
  signals_names = sig_unique;
endfunction

% Build indexed elements
function [ElemsIdx, name2idx, idx2name] = build_indexed(Elems, signals_names)
  idx2name = signals_names;
  name2idx = containers.Map();
  for i=1:numel(idx2name), name2idx(idx2name{i})=i; endfor

  ElemsIdx={};
  for e=1:numel(Elems)
    E0=Elems{e};
    E.type=E0.type;

    ins_idx=zeros(1,numel(E0.input_names));
    for k=1:numel(ins_idx)
      nm=E0.input_names{k};
      if ~isKey(name2idx,nm)
        new = numel(idx2name)+1;
        idx2name{end+1}=nm;
        name2idx(nm)=new;
      endif
      ins_idx(k)=name2idx(nm);
    endfor
    E.inputs=ins_idx;

    outnm=E0.output_name;
    if ~isKey(name2idx,outnm)
      new = numel(idx2name)+1;
      idx2name{end+1}=outnm;
      name2idx(outnm)=new;
    endif
    E.output=name2idx(outnm);

    ElemsIdx{end+1}=E;
  endfor
endfunction

% Auto-detect top inputs
function top_in = detect_top(ElemsIdx, idx2name, declared_top)
  if ~isempty(declared_top)
    top_in = declared_top;
    return;
  endif
  S=numel(idx2name);
  writers=zeros(1,S);
  for e=1:numel(ElemsIdx)
    writers(ElemsIdx{e}.output)=1;
  endfor
  top_in={};
  for i=1:S
    if writers(i)==0
      top_in{end+1}=idx2name{i};
    endif
  endfor
endfunction

% TOPOLOGICAL SORT (Kahn)
function Sorted = topo_sort(ElemsIdx)
  % Count dependencies: element depends on signals that come from other elements.
  n=numel(ElemsIdx);
  indeg=zeros(1,n);
  produces=containers.Map('KeyType','int32','ValueType','any');
  % map output -> element index
  for i=1:n
    produces(ElemsIdx{i}.output)=i;
  endfor

  AO = cell(1,n); % adjacency list: element -> dependents
  for i=1:n, AO{i}=[]; endfor

  for i=1:n
    ins = ElemsIdx{i}.inputs;
    for k=1:numel(ins)
      s=ins(k);
      if isKey(produces,s)
        src = produces(s);
        indeg(i)++;
        AO{src}=[AO{src}, i];
      endif
    endfor
  endfor

  Q=[];
  for i=1:n
    if indeg(i)==0
      Q=[Q,i];
    endif
  endfor

  Sorted={};
  while ~isempty(Q)
    u=Q(1);
    Q=Q(2:end);
    Sorted{end+1}=ElemsIdx{u};
    for v = AO{u}
      indeg(v)--;
      if indeg(v)==0
        Q=[Q,v];
      endif
    endfor
  endwhile

  if numel(Sorted)!=n
    error("Circuit has cycle / cannot topological sort");
  endif
endfunction

% simulate truth table using sorted elements
function history = simulate_sorted(ElemsSorted, idx2name, top_inputs_names)
  S=numel(idx2name);
  name2idx = containers.Map();
  for i=1:S, name2idx(idx2name{i})=i; endfor

  top_idx=zeros(1,numel(top_inputs_names));
  for k=1:numel(top_inputs_names)
    top_idx(k)=name2idx(top_inputs_names{k});
  endfor

  T = 2^numel(top_inputs_names);
  history = zeros(S,T);

  global SignalsTable;

  for t=0:(T-1)
    SignalsTable=zeros(1,S);

    % assign top inputs
    for k=1:numel(top_idx)
      bitpos = numel(top_idx)-k;
      SignalsTable(top_idx(k)) = bitget(t,bitpos+1);
    endfor

    % process sorted
    for e=1:numel(ElemsSorted)
      process(ElemsSorted{e});
    endfor

    % store
    for s=1:S
      history(s,t+1)=SignalsTable(s);
    endfor
  endfor
endfunction

% Probabilistic propagation
function pvec = prob_prop(ElemsSorted, idx2name, top_inputs_names, p_top)
  S=numel(idx2name);
  pvec=zeros(S,1);

  name2idx=containers.Map();
  for i=1:S, name2idx(idx2name{i})=i; endfor

  % assign top input probabilities
  for k=1:numel(top_inputs_names)
    pvec(name2idx(top_inputs_names{k})) = p_top(k);
  endfor

  for e=1:numel(ElemsSorted)
    E=ElemsSorted{e};
    typ=upper(E.type);
    ins=E.inputs;

    switch typ
      case 'NOT'
        pvec(E.output)=1-pvec(ins(1));
      case 'AND'
        p = 1;
        for k = 1:numel(ins)
          p = p * pvec(ins(k));
        endfor
      pvec(E.output) = p;
      otherwise
        warning(['Unsupported gate ',typ]);
    endswitch

  endfor
endfunction

% Testbench
function testbench_3_3()

  printf("\n===== TESTBENCH(Topological Sorting) =====\n");

  % Create example circuit with WRONG ORDER on purpose
  fname='circuit_unsorted.txt';
  fid=fopen(fname,'w');

  fprintf(fid,"top_inputs a b c\n");
  fprintf(fid,"AND d e f\n");     % THIS depends on e,f (should be last!)
  fprintf(fid,"NOT f c\n");       % produces f
  fprintf(fid,"AND e a b\n");     % produces e
  fclose(fid);

  printf("Created file: %s\n", fname);

  % Parse file
  [Elems, signals_names, declared_top] = parse_circuit_file(fname);

  % Build indexed
  [ElemsIdx, name2idx, idx2name] = build_indexed(Elems, signals_names);

  % Detect top inputs (A or B)
  top_inputs = detect_top(ElemsIdx, idx2name, declared_top);

  printf("Signals: "); disp(idx2name);
  printf("Top inputs: "); disp(top_inputs);

  % Perform TOPOLOGICAL SORT
  ElemsSorted = topo_sort(ElemsIdx);

  printf("\nSorted element order:\n");
  for i=1:numel(ElemsSorted)
    E=ElemsSorted{i};
    printf("[%d] %s  out=%s  inputs=", i, E.type, idx2name{E.output});
    for k=1:numel(E.inputs)
      printf("%s ", idx2name{E.inputs(k)});
    endfor
    printf("\n");
  endfor

  % SIMULATION
  history = simulate_sorted(ElemsSorted, idx2name, top_inputs);
  Esw_vec=zeros(numel(idx2name),1);
  for i=1:numel(idx2name)
    Esw_vec(i)=ComputeEsw(history(i,:));
  endfor

  printf("\n--- Esw from truth table (after topological sort) ---\n");
  for i=1:numel(idx2name)
    printf("%s : %.4f\n", idx2name{i}, Esw_vec(i));
  endfor

  % Probabilistic p=0.5
  p05 = ones(1,numel(top_inputs))*0.5;
  pvec05 = prob_prop(ElemsSorted, idx2name, top_inputs, p05);
  Esw05 = 2*pvec05.*(1-pvec05);

  printf("\n--- Probabilistic (p=0.5) ---\n");
  for i=1:numel(idx2name)
    printf("%s : p=%.4f Esw_est=%.4f\n", idx2name{i}, pvec05(i), Esw05(i));
  endfor

  % Probabilistic p=0.5332
  p12 = ones(1,numel(top_inputs))*0.5332;
  pvec12 = prob_prop(ElemsSorted, idx2name, top_inputs, p12);
  Esw12 = 2*pvec12.*(1-pvec12);

  printf("\n--- Probabilistic (p=0.5332) ---\n");
  for i=1:numel(idx2name)
    printf("%s : p=%.6f Esw_est=%.6f\n", idx2name{i}, pvec12(i), Esw12(i));
  endfor

  printf("\n===== END TESTBENCH =====\n\n");
endfunction

testbench_3_3();
