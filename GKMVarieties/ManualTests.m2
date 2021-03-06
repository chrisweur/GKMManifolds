

----------< tGeneralizedFlagVariety tests >-------------
restart
needsPackage "GKMManifolds"

TEST ///
--the flag variety of 1-dim in 2-dim in ambient 3-dim space, as proj var embedded in P7
--(here, dim means linear space dim, not projective dim)
X = tGeneralizedFlagVariety("A",2,{1,2})
peek X
H = X.charts
G = momentGraph X
peek G
G.edges
graph G
C = ampleTKClass X
peek C
isWellDefined C
lieType X
P = bruhatOrder X
displayPoset(P, SuppressLabels => false)

--if a character ring is pre-determined
R = makeCharRing 3
X = tGeneralizedFlagVariety("A",2,{1,2},R)
C = ampleTKClass X
ring first values C.hilb === R
peek C
isWellDefined C

--ordinary Grassmannian(2,4)
X = tGeneralizedFlagVariety("A",3,{2})
peek X
C = ampleTKClass X
tChi C
Y = tGeneralizedSchubertVariety(X,{set{0,1}}) --basically same as X
peek Y
Z = tGeneralizedSchubertVariety(X,{set{0,2}})
peek Z
W = tGeneralizedSchubertVariety(X,{set{1,2}})
peek W
displayPoset cellOrder momentGraph X
displayPoset cellOrder momentGraph Z


--same variety but embedded differently in P14
X = tGeneralizedFlagVariety("A",2,{1,1,2})
peek X
H = X.charts
G = momentGraph X
peek G
G.edges
C = ampleTKClass X
peek C

--Lagrangian Grassmannian(2,4)
X = tGeneralizedFlagVariety("C",2,{2})
peek X
H = X.charts
G = momentGraph X
peek G
G.edges
graph G
C = ampleTKClass X
peek C
isWellDefined C
lieType X
P = bruhatOrder X
displayPoset(P, SuppressLabels => false)

--Lagrangian Grassmannian(3,6)
X = tGeneralizedFlagVariety("C",3,{3})
peek X
H = X.charts
netList {(first keys H), H#(first keys H)}
G = momentGraph X
peek G
G.edges
C = ampleTKClass X
peek C

--isotropic Grassmannian(1,2,3;6) (i.e. SpGr(1,2,3;6))
X = tGeneralizedFlagVariety("C",3,{1,2,3})
peek X
H = X.charts
netList {(first keys H), H#(first keys H)}
G = momentGraph X
peek G
G.edges
C = ampleTKClass X
peek C
isWellDefined C
P = bruhatOrder X
displayPoset P

X = tGeneralizedFlagVariety("B",3,{2})
peek X
H = X.charts
G = momentGraph X
peek G
G.edges
C = ampleTKClass X
peek C


--spin groups are not implemented yet
X = tGeneralizedFlagVariety("B",3,{3})





--even orthogonal Grassmannians are very tricky!
--All fine as long as k < n-1, where we consider k-dim'l isotropic subspace of a 2n-dim'l space.
--When k = n-1, we need consider the sum of the two fundamental weights
--When k = n, it seems like we can one conn component per fundamental weight (? check)


--orthogonal Grassmannian(2,8)
X = tGeneralizedFlagVariety("D",4,{2})
peek X
H = X.charts
netList {(first keys H), H#(first keys H)}
G = momentGraph X
graph G
peek G
G.edges
C = ampleTKClass X
peek C


--orthogonal Grassmannian(3,8) (i.e. SOGr(3,8))
--I think? This needs to be checked
X = tGeneralizedFlagVariety("D",4,{3,4})
X.points
peek X
H = X.charts
H#{set{0,1,2}}
G = momentGraph X
graph G
peek G
G.edges
C = ampleTKClass X
peek C

--again, spin groups not implemented
X = tGeneralizedFlagVariety("D",4,{4})
X = tGeneralizedFlagVariety("D",4,{3})


--one of two connected components (I think?) 
--of orthogonal Grassmannian(4,8) (i.e. SOGr(4,8))
X = tGeneralizedFlagVariety("D",4,{4,4})
peek X
H = X.charts
netList {(first keys H), H#(first keys H)}
G = momentGraph X
graph G
peek G
G.edges
C = ampleTKClass X
peek C

--the other half of orthogonal Grassmannian(4,8) (i.e. SOGr(4,8))
X = tGeneralizedFlagVariety("D",3,{3,3})
peek X
H = X.charts
netList {(first keys H), H#(first keys H)}
G = momentGraph X
graph G
peek G
G.edges
C = ampleTKClass X
peek C


-------------------------------------------< speed tests >-------------------------------------
--Seems like for Grassmannians the functions "tGeneralizedFlagVariety" and "tFlagVariety"
--are about the same speed because the limitation is in the function "permutations"
--However, for partial flag varities, the "tGeneralizedFlagVariety" is considerably slower
--Similarly in other Lie types than "A", Grassmannians are pretty fast, limited by the
--function "signedPermutations", but much slower for partial flag varieties.


restart
uninstallPackage"GKMManifolds"
installPackage "GKMManifolds"


--Grassmannians
time X = tGeneralizedFlagVariety("A", 8, {3}) -- 3 seconds
time X = tGeneralizedFlagVariety("A", 8, {4}) -- 3 seconds
time X = tGeneralizedFlagVariety("A", 9, {4}) -- 29 seconds
time permutations {1,2,3,4,5,6,7,8,9,10}; -- 27 seconds
--so Gr(4,10) above is slow due to permutations being slow
time X = tFlagVariety({4},9) -- 4 seconds
time X = tFlagVariety({3},9) -- 4 seconds

--full flag varieties
time X = tGeneralizedFlagVariety("A", 4, {1,2,3,4}) -- 0.3 seconds
time X = tGeneralizedFlagVariety("A", 5, {1,2,3,4,5}) -- 6 seconds
--time X = tGeneralizedFlagVariety("A", 6, {1,2,3,4,5,6}) -- don't try on laptop
time X = tFlagVariety({1,2,3,4,5,6},7) -- 3 seconds!!

--isotropic Grassmannians
time X = tGeneralizedFlagVariety("B", 7, {4}) -- 3 seconds
time X = tGeneralizedFlagVariety("B", 7, {6}) -- 3 seconds
time X = tGeneralizedFlagVariety("B", 7, {7,7}) -- 2 seconds
time X = tGeneralizedFlagVariety("B", 8, {8,8}) -- 34 seconds
time X = tGeneralizedFlagVariety("B", 8, {4}) -- 34 seconds
time signedPermutations {1,2,3,4,5,6,7,8}; -- 28 seconds
--again, the slowness for isotropic Grassmannians is largely due to signPermutations

--flag isotropic
time X = tGeneralizedFlagVariety("B", 4, {1,2,3,4,4}) -- 3 seconds
time X = tGeneralizedFlagVariety("B", 5, {1,2,3,4}) -- 40 seconds

--few other types
time X = tGeneralizedFlagVariety("C", 7, {4}) -- 3 seconds
time X = tGeneralizedFlagVariety("D", 7, {6,7}) -- 3 seconds
time X = tGeneralizedFlagVariety("C", 5, {1,2,4}) -- 7 seconds
time X = tGeneralizedFlagVariety("D", 5, {2,3,4,5}) -- 5 seconds

--a test for normal toric varieties: Hirezebruch surface H_2
restart
needsPackage "GKMManifolds"
X = kleinschmidt(2,{2})
peek X
Y = tVariety X
peek Y
peek momentGraph Y
normalToricVariety Y
antiK = - toricDivisor X
TantiK = tKClass(Y,antiK)
peek TantiK
tChi TantiK

--a sanity check with projective space P^3
P3 = tProjectiveSpace 3
R = P3.charRing;
describe R
charts P3
G = momentGraph P3
G.edges
peek G
graph G


assert isWellDefined C
badTKC = tKClass(P3,{R_0,R_0,R_0,R_1})
peek badTKC
assert not isWellDefined badTKC


--product of T-varieties check with P^1
P1 = tProjectiveSpace 1
P1xP1 = P1 ** P1
peek P1xP1
G = P1.momentGraph
GxG = G ** G
peek GxG
graph GxG

--test of affineToricRing
B = {{1,0},{0,1},{1,1},{1,-1}}
affineToricRing B
hilbertSeries(oo, Reduce => true)


----------< TOrbClosure tests >-------------

restart
needsPackage "GKMManifolds"

-- Easy test (can compre with Speyer/Fink pg 17)
M = matrix(QQ,{{1,1,0,1},{0,0,1,1}})
N = matrix(QQ,{{1,1,1,3},{1,1,2,1}})
X = tGeneralizedFlagVariety("A",3,{2})
time C1 = TOrbClosure(X,{M})
time C2 = TOrbClosure(X,{M})
peek C1
peek C2
C = tKClass(X,flagMatroid(M,{2})); peek C


--Lagrangian Grassmannian test
M = matrix(QQ,{{1,0,1,2},{0,1,2,1}})
X = tGeneralizedFlagVariety("C",2,{2})
C = TOrbClosure(X,{M})
peek C
isWellDefined C


-- Type "A"
M = matrix(QQ,{{1,1,0,1},{0,0,1,1}})
N = matrix(QQ,{{1,0,0,0},{0,1,0,0}})
X = tGeneralizedFlagVariety("A",3,{2})
time C = TOrbClosure(X,{M});
peek C
isWellDefined C
time D = TOrbClosure(X,{N}); --example where the matroid has only one basis
peek D
D.hilb#{set{0,1}}
factor oo

Y = tGeneralizedFlagVariety("A",2,{2,1})
M = matrix(QQ,{{1,0,0},{0,1,1}})
N = matrix(QQ,{{1,1,1}})
time C = TOrbClosure(Y,{N,M}); peek C



-- Type "C"
M = matrix(QQ,{{1,0,1,3},{0,1,3,1}})
N = matrix(QQ,{{1,0,1,0},{0,1,0,1}})
X = tGeneralizedFlagVariety("C",2,{2})
time C = TOrbClosure(X,{M}); D = TOrbClosure(X,{N});
peek C
peek D
{C,D}/isWellDefined



M = matrix{{1,1,1,0,0,0},{0,0,0,1,1,-2}}
X = tGeneralizedFlagVariety("C",3,{2})
time C = TOrbClosure(X,{M})

N = matrix{{1,1,1,1,1,-2}}
Y = tGeneralizedFlagVariety("C",3,{2,1})
time D = TOrbClosure(Y,{N,M});
peek D






-- Error testing
M = matrix(QQ,{{1,0,1,3},{0,1,3,1}})
X = tProjectiveSpace 3
C = tOrbitClosure(X,M)

X = tGeneralizedFlagVariety("A",3,{3})
C = TOrbClosure(X,{M})




-- Sanity check
-- The closure of the following is just a point


A = matrix(QQ,{{1,0,2,1},{0,1,1,2}})
X = tGeneralizedFlagVariety("C",2,{2})
C = tOrbitClosure(X,A); peek C



M = matrix(QQ,{{1,2,0,0},{1,2,0,0}})
X = tGeneralizedFlagVariety("A",3,{1})
C = tOrbitClosure(X,M); peek C
M = matrix(QQ,{{1,2,0,0}})


-- tests for Chow Class basics

F2 = hirzebruchSurface 2
X = makeGKMVariety F2
G = momentGraph X
R = G.HTpt
C = trivialChowClass X
C1 = makeChowClass(X, {-R_0, -R_0 - R_1, 2 * R_0, -R_1})
C2 = makeChowClass(X, {R_0, R_1, 2 * R_0, 3 * R_1})
isWellDefined C -- true
isWellDefined C1 -- true
isWellDefined C2 -- false
(C1 + C2).EqnMults
(C1 * C2).EqnMults
(C1^2).EqnMults

-- tests for equiCohomologyRing and cohomologyRing

PP3 = projectiveSpace 3
G = momentGraph PP3
P = poset(V, {{V_0, V_1}, {V_1, V_2}, {V_2, V_3}})
cellOrder(G, P)
equiCohomologyRing(momentGraph projectiveSpace 4);

-- tests for toric divisor -> Chow class

rayList = {{1,0},{0,1},{-1,1},{-1,0},{0,-1}}
coneList = {{0,1},{1,2},{2,3},{3,4},{0,4}}
X = normalToricVariety(rayList, coneList)
D = toricDivisor(X)
X = makeGKMVariety(X)
C = makeChowClass(X, D)

-- tests for pullback, *pushforward*


