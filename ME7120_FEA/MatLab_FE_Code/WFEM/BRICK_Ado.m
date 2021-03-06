function out=BRICK_Ado(mode,b,c,d,e)
  
% BEAM2 does as listed below. It is an Euler-Bernoulli
% beam/rod/torsion model. 
% Beam properties (bprops) are in the order
% bprops=[E G rho A1 A2 J1 J2 Ixx1 Ixx2 Iyy1 Iyy2]
% Third node is in the middle.
% Fourth "node" defines the beam y plane and is actually from the
% points array.
%
% Defining beam element properties in wfem input file:
% element properties
%   E G rho A1 A2 J1 J2 Izz1 Izz2 Iyy1 Iyy2 
% Torsional rigidity, $J$, must be less than or equal
% to $Iyy+Izz$ at any given cross section.  
%
% Defining beam2 element in wfem input file:
%   node1 node2 node3 pointnumber materialnumber 

%
% See wfem.m for more explanation.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Variables (global):
% -------------------
% K       :    Global stiffness matrix
% M       :    Global mass matrix
% nodes   :    [x y z] nodal locations
global K
global M
global nodes
global elprops
global element
global points
global lines
%global DoverL

%
% Variables (local):
% ------------------
% bnodes  :    node/point numbers for actual beam nodes 1-2-3 and point
% k       :    stiffness matrix in local coordiates
% kg      :    stiffness matrix rotated into global coordinates
% m       :    mass matrix in local coordiates
% mg      :    mass matrix rotated into global coordinates
% 

out=0;
if strcmp(mode,'numofnodes')
    % This allows a code to find out how many nodes this element has
    out=8;
end
if strcmp(mode,'generate')
  elnum=c;%When this mode is called, the element number is the 3rd
          %argument. 
          %The second argument (b) is the element
          %definition. For this element b is
          %node1 node2 point(for rotation) and material#
          
  if length(b)==9
      element(elnum).nodes=b(1:8);
      element(elnum).properties=b(9);
      %element(elnum).point=b(3);
  else 
	  b
      %There have to be four numbers on a line defining the
      %element. 
      warndlg(['Element ' num2str(elnum) ' on line ' ...
               num2str(element(elnum).lineno) ' entered incorrectly.'], ...
              ['Malformed Element'],'modal')
      return
  end
 
end

% Here we figure out what the beam properties mean. If you need
% them in a mode, that mode should be in the if on the next line.

if strcmp(mode,'make')||strcmp(mode,'istrainforces')
  elnum=b;% When this mode is called, the element number is given
          % as the second input.
          
  bnodes=[element(elnum).nodes];% The point is referred to
  % as node 4 below, although it actually calls the array points to get its
  % location. Its not really a node, but just a point that helps define
  % orientation. Your element may not need such a reference point.
  
  bprops=elprops(element(elnum).properties).a;% element(elnum).properties 
  % stores the properties number of the current elnum. elprops contains 
  % this data. This is precisely the material properties line in an
  % array. You can pull out any value you need for your use. 
  
  if length(bprops)==3
      % Should only need 3 properties to generate the brick element
      E=bprops(1); mu=bprops(2); rho=bprops(3);
      
  else
      warndlg(['The number of material properties set for ' ...
               'this element (' num2str(length(bprops)) ') isn''t ' ...
               'appropriate for a brick element. '      ...
               'Please refer to the manual.'],...
              'Bad element property definition.','modal');
  end
end

if strcmp(mode,'make') % Define BRICK node locations for easy later referencing
  
  x1=nodes(bnodes(1),1);  % Location of node 1 x1 y1 z1
  y1=nodes(bnodes(1),2);
  z1=nodes(bnodes(1),3);
  x2=nodes(bnodes(2),1);  % Location of node 2 x2 y2 z2
  y2=nodes(bnodes(2),2);
  z2=nodes(bnodes(2),3);
  x3=nodes(bnodes(3),1);  % Location of node 3 x3 y3 z3
  y3=nodes(bnodes(3),2);
  z3=nodes(bnodes(3),3);
  x4=nodes(bnodes(4),1);  % Location of node 4 x4 y4 z4
  y4=nodes(bnodes(4),2);
  z4=nodes(bnodes(4),3);
  x5=nodes(bnodes(5),1);  % Location of node 5 x5 y5 z5
  y5=nodes(bnodes(5),2);
  z5=nodes(bnodes(5),3); 
  x6=nodes(bnodes(6),1);  % Location of node 6 x6 y6 z6
  y6=nodes(bnodes(6),2);
  z6=nodes(bnodes(6),3); 
  x7=nodes(bnodes(7),1);  % Location of node 7 x7 y7 z7
  y7=nodes(bnodes(7),2);
  z7=nodes(bnodes(7),3); 
  x8=nodes(bnodes(8),1);  % Location of node 8 x8 y8 z8
  y8=nodes(bnodes(8),2);
  z8=nodes(bnodes(8),3); 
  %
  
  global_nodes = [[x1 y1 z1]; [x2 y2 z2]; [x3 y3 z3]; [x4 y4 z4]...
      [x5 y5 z5]; [x6 y6 z6]; [x7 y7 z7]; [x8 y8 z8]];

  % Number of Gauss points for integration of BRICK element
  % numbeamgauss=2; [bgpts,bgpw]=gauss(numbeamgauss);
  
  num_gauss=2
  [int_p, int_w] = gauss(num_gauss)
  intPts=zeros(num_gauss^3,3);
  intWts=zeros(num_gauss^3,3);
  index=0;
  
  for i=1:num_gauss
      for j=1:num_gauss
          for k=1:num_gauss
              index=index+1
              intPts(index,:) = [int_p(i) int_p(j) int_p(k)];
              intWts(index,:) = [int_w(i) int_w(j) int_w(k)];
          end
      end
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 
  % Derivation of Stiffness matrix
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  Em=getE(E,mu);
  
  % For this BRICK, 8 nodes, 3DOF each, is a 24 by 24 matrix. 
  B=zeros(6,24);
  Ke=zeros(24,24);
  id=[1 4 7 10 13 16 19 22];

  propertynum=num2str(element(elnum).properties);
  
  for p=1:num_gauss^3
      r = intPts(p,1);
      s = intPts(p,2);
      t = intPts(p,3);
      
      dN=getdN(r,s,t);
      
      J=dN*global_nodes;
      JDet = det(J);
      
      for q=1:8
          dN_i = dN(:,q);
          
          Bi=[dot(J(1,:),dN_i) 0 0;
              0 dot(J(2,:),dN_i) 0;
              0 0 dot(J(3,:),dN_i);
              dot(J(2,:),dN_i) dot(J(1,:),dN_i) 0;
              0 dot(J(3,:),dN_i) dot(J(2,:),dN_i);
              dot(J(3,:),dN_i) 0 dot(J(1,:),dN_i)];
          B(1:end, id(q):id(q)+2) = Bi(1:end, 1:end);
      end
      
      Ki = prod(intWts(p,1:end))*JDet*(B'*Em*B);
      
      Ke=Ke+Ki;
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % 
  % Derivation of Mass matrices
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  Me=zeros(24,24);
  %Loop to construct BRICK consistent mass matrix
  for p=1:num_gauss^3
      r = intPts(p,1);
      s = intPts(p,2);
      t = intPts(p,3);
      
      Ne=getN(r,s,t);
      
      Mi = rho*prod(intWts(p,1:end))*JDet*(Ne'*Ne);
      
      Me=Me+Mi;
  end
  
%   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   %
%   % Coordinate rotations
%   %
%   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
%   R1=([x2 y2 z2]-[x1 y1 z1]);% Vector along element
%   lam1=R1/norm(R1);% Unit direction
%   R2=([x4 y4 z4]-[x1 y1 z1]);% Unit direction to point
%   R2perp=R2-dot(R2,lam1)*lam1;% Part of R2 perpendicular to lam1
%   udirec=0;
%   while norm(R2perp)<10*eps
%     udirec=udirec+1;
%     [minval,minloc]=min(lam1);
%     R2perp=zeros(1,3);
%     R2perp(udirec)=1;
%     R2perp=R2perp-dot(R2perp,lam1)*lam1;
%   end
%   %Make the unit direction vectors for rotating and put them in the
%   %rotation matrix. 
%   lam2=R2perp/norm(R2perp);
%   lam3=cross(lam1,lam2);
%   lamloc=[lam1;lam2;lam3];
%   lam=sparse(12,12);
%   lam(1:3,1:3)=lamloc;
%   lam(4:6,4:6)=lamloc;
%   lam(7:9,7:9)=lamloc;
%   lam(10:12,10:12)=lamloc;
%   
%   % Updating global vars
%   element(elnum).lambda=lam;
%   element(elnum).m=m;
%   element(elnum).k=k;
% 
%   kg=lam'*k*lam;
%   mg=lam'*m*lam;

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %
  % Assembling matrices into global matrices
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  bn1=bnodes(1);bn2=bnodes(2);%bn3=bnodes(3);
  indices=[bn1*6+(-5:0) bn2*6+(-5:0)];% bn3*6+(-5:0)] ;

  K(indices,indices)=K(indices,indices)+kg;
  M(indices,indices)=M(indices,indices)+mg;

  % Connecting node information
  numlines=size(lines,1);
  lines(numlines+1,:)=[bn1 bn2];
  
  end
end

% function [NN] = getNN(r, s, t) %Computes N^T*N for mass matrix calc.
% 
% N1 = 1/8*((1-r)*(1-s)*(1-t));
% N2 = 1/8*((1+r)*(1-s)*(1-t));
% N3 = 1/8*((1+r)*(1+s)*(1-t));
% N4 = 1/8*((1-r)*(1+s)*(1-t));
% 
% N5 = 1/8*((1-r)*(1-s)*(1+t));
% N6 = 1/8*((1+r)*(1-s)*(1+t));
% N7 = 1/8*((1+r)*(1+s)*(1+t));
% N8 = 1/8*((1-r)*(1+s)*(1+t));
% 
% N=[N1*eye(3) N2*eye(3) N3*eye(3) N4*eye(3) N5*eye(3) N6*eye(3)...
%     N7*eye(3) N8*eye(3)];
%     
% end
% 
% function [dN] = getdN(r, s, t) %Computes N^T*N for mass matrix calc.
%     
% dN1r = -((s - 1)*(t - 1))/8;
% dN1s = -((r - 1)*(t - 1))/8;
% dN1t = -((r - 1)*(s - 1))/8;
% 
% dN2r = ((s - 1)*(t - 1))/8;
% dN2s = ((r + 1)*(t - 1))/8;
% dN2t = ((r + 1)*(s - 1))/8;
% 
% dN3r = -((s + 1)*(t - 1))/8;
% dN3s = -((r + 1)*(t - 1))/8;
% dN3t = -((r + 1)*(s + 1))/8;
% 
% dN4r = ((s + 1)*(t - 1))/8;
% dN4s = ((r - 1)*(t - 1))/8;
% dN4t = ((r - 1)*(s + 1))/8;
% 
% dN5r = ((s - 1)*(t + 1))/8;
% dN5s = ((r - 1)*(t + 1))/8;
% dN5t = ((r - 1)*(s - 1))/8;
% 
% dN6r = -((s - 1)*(t + 1))/8;
% dN6s = -((r + 1)*(t + 1))/8;
% dN6t = -((r + 1)*(s - 1))/8;
% 
% dN7r = ((s + 1)*(t + 1))/8;
% dN7s = ((r + 1)*(t + 1))/8;
% dN7t = ((r + 1)*(s + 1))/8;
% 
% dN8r = -((s + 1)*(t + 1))/8;
% dN8s = -((r - 1)*(t + 1))/8;
% dN8t = -((r - 1)*(s + 1))/8;
% 
% dN=[[dN1r dN1s dN1t]' [dN2r dN2s dN2t]' [dN3r dN3s dN3t]'...
%     [dN4r dN4s dN4t]' [dN5r dN5s dN5t]' [dN6r dN6s dN6t]'...
%     [dN7r dN7s dN7t]' [dN8r dN8s dN8t]'];
% 
% end

