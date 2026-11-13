% ============================================================
% LAB 4.2 - Παραγωγή stress-test με Γενετικό Αλγόριθμο
% με αντικατάσταση process(obj) & findProcessOrder(obj)
% ============================================================

clear all; close all; clc;

% ============================================================
% === spByType: εκτελεί την κατάλληλη λογική πύλη ===
% ============================================================
function s = spByType(gtype, inputs)
  switch upper(gtype)
    case 'AND',  s = prod(inputs);
    case 'OR',   s = double(any(inputs));
    case 'NAND', s = 1 - prod(inputs);
    case 'NOR',  s = 1 - double(any(inputs));
    case 'XOR',  s = mod(sum(inputs),2);
    case 'XNOR', s = 1 - mod(sum(inputs),2);
    case 'NOT',  s = 1 - inputs(1);
    otherwise,   error(['Unsupported gate: ', gtype]);
  end
endfunction

% ============================================================
% === process(obj): εκτέλεση κυκλώματος με delays ===
% ============================================================
function updated = process(obj)
  if isempty(obj.ElementsSorted)
    obj = findProcessOrder(obj);
  end
  obj.delays = zeros(size(obj.Signals));
  for j = 1:numel(obj.ElementsSorted)
    ele = obj.Elements{obj.ElementsSorted(j)};
    inputValues = obj.Signals(ele.inputs);
    inputDelays = obj.delays(ele.inputs);
    obj.delays(ele.output) = max(inputDelays) + 1.0;
    obj.Signals(ele.output) = spByType(ele.type, inputValues);
  end
  updated = obj;
endfunction

% ============================================================
% === findProcessOrder(obj): τοπολογική ταξινόμηση ===
% ============================================================
function obj = findProcessOrder(obj)
  numSignals = numel(obj.Signals);
  numElements = numel(obj.Elements);
  signalsUpdated = zeros(1,numSignals);
  elementsUpdated = zeros(1,numElements);
  obj.ElementsSorted = [];
  for j = 1:numel(obj.TlpInputs)
    signalsUpdated(obj.TlpInputs(j)) = 1;
  end
  updatedNumberOfElements = 0;
  while updatedNumberOfElements < numElements
    progressMade = false;
    for j = 1:numElements
      if elementsUpdated(j)==1, continue; endif
      ele = obj.Elements{j};
      ready = true;
      for i = 1:numel(ele.inputs)
        if signalsUpdated(ele.inputs(i))==0
          ready = false; break;
        endif
      end
      if ready
        updatedNumberOfElements += 1;
        elementsUpdated(j)=1;
        obj.ElementsSorted(end+1)=j;
        signalsUpdated(ele.output)=1;
        progressMade = true;
      endif
    end
    if ~progressMade
      error("findProcessOrder: κύκλος ή λάθος περιγραφή κυκλώματος.");
    endif
  end
endfunction

% ============================================================
% === Parser κυκλώματος ===
% ============================================================
function [obj, top_inputs] = load_circuit(filename)
  fid=fopen(filename,'r'); if fid<0, error(['Cannot open ',filename]); endif
  Elems={}; signals={}; declared_top={};
  while true
    L=fgetl(fid); if ~ischar(L), break; endif
    L=strtrim(L); if isempty(L), continue; endif
    if startsWith(L,'//')||startsWith(L,'#'), continue; endif
    T=strsplit(L);
    if strcmpi(T{1},'tlpinputs')
      declared_top = T(2:end);
      for k=1:numel(declared_top), signals{end+1}=declared_top{k}; endfor
      continue
    endif
    gate=upper(T{1}); out=T{2}; ins=T(3:end);
    E.type=gate; E.output_name=out; E.input_names=ins;
    Elems{end+1}=E;
    signals{end+1}=out;
    for k=1:numel(ins), signals{end+1}=ins{k}; endfor
  endwhile
  fclose(fid);

  % δημιουργία mapping ονομάτων->δείκτη
  sig_unique={};
  for i=1:numel(signals)
    if ~any(strcmp(sig_unique,signals{i}))
      sig_unique{end+1}=signals{i};
    endif
  endfor
  name2idx=containers.Map();
  for i=1:numel(sig_unique), name2idx(sig_unique{i})=i; endfor

  ElemsIdx={};
  for e=1:numel(Elems)
    E0=Elems{e}; E.type=E0.type;
    E.inputs=zeros(1,numel(E0.input_names));
    for k=1:numel(E.inputs)
      E.inputs(k)=name2idx(E0.input_names{k});
    end
    E.output=name2idx(E0.output_name);
    ElemsIdx{end+1}=E;
  endfor

  top_inputs = zeros(1,numel(declared_top));
  for k=1:numel(declared_top)
    top_inputs(k)=name2idx(declared_top{k});
  endfor

  obj.Elements = ElemsIdx;
  obj.Signals = zeros(1,numel(sig_unique));
  obj.delays = zeros(1,numel(sig_unique));
  obj.TlpInputs = top_inputs;
  obj.ElementsSorted = [];
endfunction

% ============================================================
% === Αξιολόγηση workload ===
% ============================================================
function score = evaluate_workload(workload, obj)
  L = size(workload,1);
  for i=1:L
    obj.Signals(obj.TlpInputs) = workload(i,:);
    obj = process(obj);
    if i==1
      SignalsBefore = obj.Signals;
    else
      SignalsAfter = obj.Signals;
    end
  end
  diffs = (SignalsBefore~=SignalsAfter);
  diffs(obj.TlpInputs)=0;
  score=sum(diffs);
endfunction

% ============================================================
% === Γενετικός Αλγόριθμος ===
% ============================================================

printf("=== LAB 4.2 : Genetic Algorithm stress-test ===\n");

[obj, top_inputs] = load_circuit("Lab4_circuit.txt");

L=2; N=30; m=0.05; generations=100;
num_inputs=numel(top_inputs);

% Αρχικός πληθυσμός
Population = cell(1,N);
for i=1:N
  Population{i} = randi([0,1], L, num_inputs);
endfor

scoreG = zeros(1,generations);

for g=1:generations
  scores = zeros(1,N);
  for i=1:N
    scores(i) = evaluate_workload(Population{i}, obj);
  endfor

  [bestScore,bestIdx] = max(scores);
  bestIndividual = Population{bestIdx};
  scoreG(g)=bestScore;

  % Επιλογή γονέων
  [~, sortedIdx] = sort(scores, 'descend');
  parentA = Population{sortedIdx(1)};
  parentB = Population{sortedIdx(2)};

  % Δημιουργία νέου πληθυσμού
  NewPop = cell(1,N);
  NewPop{1}=parentA;
  NewPop{2}=parentB;

  for i=3:N
    R = randi([1,L]);
    if rand()<0.5
      child = [parentA(1:R,:); parentB(R+1:end,:)];
    else
      child = [parentB(1:R,:); parentA(R+1:end,:)];
    endif
    if rand()<m
      rpos = randi(numel(child));
      child(rpos)=1-child(rpos);
    endif
    NewPop{i}=child;
  endfor

  Population = NewPop;
  printf("Generation %3d | Best score = %d\n", g, bestScore);
endfor

% ============================================================
% === Αποτελέσματα ===
% ============================================================
figure;
plot(1:generations, scoreG, 'r.-','LineWidth',1.5);
xlabel('Generation');
ylabel('Best score (εναλλαγές)');
title('¶σκηση 4.2 - Εξέλιξη Γενετικού Αλγορίθμου');
grid on;
saveas(gcf,'lab4_2_GA.png');
save('best_workload.mat','bestIndividual','bestScore');

printf("Αποθηκεύτηκε γράφημα lab4_2_GA.png και αρχείο best_workload.mat\n");

