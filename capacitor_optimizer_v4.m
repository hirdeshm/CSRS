clc; clear; format short g;
% CSROS V4: screening estimates, not a final engineering approval.
Vin=24; Vout=12; L=1e-3; fs=50e3; Rload=3.75;
VrippleMax=0.1; voltageMargin=1.20; requiredLifetime_h=5000;
W_electrical=.30; W_reliability=.30; W_lifetime=.25; W_cost=.15;
W_ripple=.70; W_loss=.30;
Manufacturer=["Panasonic";"Panasonic";"Panasonic";"KEMET";"KEMET";"KEMET";"Nichicon";"Panasonic";"Panasonic";"Panasonic"];
PartNumber=["EEE-HB1V220AP";"25TQC22MD2";"35SVPD22M";"T521V226M025ATE045";"T521B226M025ATE100";"A758EK226M1EAAE050";"FP-025ME220M-SSR";"35SVF22M";"35SVPF22M";"EEE-FN1V220R"];
C_uF=22*ones(10,1); Tolerance_pct=20*ones(10,1);
Voltage_V=[35;25;35;25;25;25;25;35;35;35];
ESR_Ohm=[NaN;.060;.050;.045;.100;.050;.040;.035;.035;.700];
RippleCurrent_A=[.055;1.4;2.3;2.0;1.1;2.0;2.1;.82;2.6;.16];
RatingConditionsVerified=false(10,1);
RatedLife_h=NaN(10,1); Tcap_C=NaN(10,1); Price=NaN(10,1);

D=Vout/Vin; deltaIL=(Vin-Vout)*D/(L*fs); IcRMS=deltaIL/(2*sqrt(3));
Iout=Vout/Rload; Pout=Vout*Iout; n=numel(PartNumber);
Cmin_uF=C_uF.*(1-Tolerance_pct/100);
Crequired_uF=deltaIL/(8*fs*VrippleMax)*1e6;
VrippleCap_V=deltaIL./(8*fs.*Cmin_uF*1e-6);
ESRknown=isfinite(ESR_Ohm);
VrippleESR_V=NaN(n,1); ESRLoss_W=NaN(n,1); VrippleTotal_V=NaN(n,1);
VrippleESR_V(ESRknown)=deltaIL.*ESR_Ohm(ESRknown);
ESRLoss_W(ESRknown)=IcRMS^2.*ESR_Ohm(ESRknown);
VrippleTotal_V(ESRknown)=VrippleCap_V(ESRknown)+VrippleESR_V(ESRknown);
VoltageOK=Voltage_V>=voltageMargin*Vout;
CapacitanceOK=Cmin_uF>=Crequired_uF;
CurrentOK=RippleCurrent_A>=IcRMS; % provisional only; conditions may differ
RippleOK=isfinite(VrippleTotal_V)&VrippleTotal_V<=VrippleMax;
FullyQualified=VoltageOK&CapacitanceOK&CurrentOK&RippleOK&ESRknown&RatingConditionsVerified;
ProvisionalPass=VoltageOK&CapacitanceOK&CurrentOK&RippleOK&ESRknown;
RippleScore=normalizeLowerBetter(VrippleTotal_V);
LossScore=normalizeLowerBetter(ESRLoss_W);
ElectricalScore=NaN(n,1); ok=isfinite(RippleScore)&isfinite(LossScore);
ElectricalScore(ok)=W_ripple*RippleScore(ok)+W_loss*LossScore(ok);
ElectricalScore(~ProvisionalPass)=NaN;
ReliabilityScore=NaN(n,1);
okrel=RatingConditionsVerified&isfinite(RippleCurrent_A)&RippleCurrent_A>0;
margin=RippleCurrent_A(okrel)./IcRMS;
ReliabilityScore(okrel)=min(100,max(0,100*margin/2));
LifetimeScore=NaN(n,1); oklife=isfinite(RatedLife_h)&RatedLife_h>0&isfinite(Tcap_C);
LifetimeScore(oklife)=min(100,max(0,100*RatedLife_h(oklife)/requiredLifetime_h));
CostScore=normalizeLowerBetter(Price);
FinalScore=NaN(n,1);
allKnown=isfinite(ElectricalScore)&isfinite(ReliabilityScore)&isfinite(LifetimeScore)&isfinite(CostScore);
okfinal=FullyQualified&allKnown;
FinalScore(okfinal)=W_electrical*ElectricalScore(okfinal)+W_reliability*ReliabilityScore(okfinal)+W_lifetime*LifetimeScore(okfinal)+W_cost*CostScore(okfinal);
Results=table(Manufacturer,PartNumber,C_uF,Cmin_uF,Voltage_V,ESR_Ohm,RippleCurrent_A,VrippleCap_V,VrippleESR_V,VrippleTotal_V,ESRLoss_W,VoltageOK,CapacitanceOK,CurrentOK,RippleOK,ProvisionalPass,FullyQualified,RippleScore,LossScore,ElectricalScore,ReliabilityScore,LifetimeScore,CostScore,FinalScore);
fprintf('\\nDuty=%.3f, dIL=%.4f A p-p, IcRMS=%.4f A\\n',D,deltaIL,IcRMS);
fprintf('Iout=%.2f A, Pout=%.2f W, ideal Cmin=%.2f uF\\n',Iout,Pout,Crequired_uF);
disp('=== ALL CANDIDATES ==='); disp(Results);
idx=find(ProvisionalPass&isfinite(ElectricalScore));
if ~isempty(idx)
 Ranked=Results(idx,:); Ranked=sortrows(Ranked,'ElectricalScore','descend');
 ProvisionalRank=(1:height(Ranked))'; Ranked=[table(ProvisionalRank),Ranked];
 disp('=== PROVISIONAL ELECTRICAL RANKING ===');
 disp(Ranked(:,{'ProvisionalRank','Manufacturer','PartNumber','VrippleTotal_V','ESRLoss_W','ElectricalScore','FullyQualified'}));
else, disp('No candidates passed provisional screening.'); end
idx=find(isfinite(FinalScore));
if ~isempty(idx)
 FinalRanked=Results(idx,:); FinalRanked=sortrows(FinalRanked,'FinalScore','descend');
 FinalRank=(1:height(FinalRanked))'; FinalRanked=[table(FinalRank),FinalRanked];
 disp('=== FINAL QUALIFIED RANKING ===');
 disp(FinalRanked(:,{'FinalRank','Manufacturer','PartNumber','ElectricalScore','ReliabilityScore','LifetimeScore','CostScore','FinalScore'}));
else, disp('No final score: verify datasheets and enter price/lifetime/temperature.'); end
fprintf('Strictly qualified: %d of %d\\n',sum(FullyQualified),n);
function score=normalizeLowerBetter(values)
score=NaN(size(values)); valid=isfinite(values); if ~any(valid), return; end
x=values(valid); lo=min(x); hi=max(x);
if hi==lo, score(valid)=100; else, score(valid)=100*(hi-x)/(hi-lo); end
end
