newPackage("GKMManifolds",
	Version => "0.1",
	Date => "August 1, 2020",
	Authors => {
	    {Name => "Chris Eur",
       	     Email => "chriseur@stanford.edu",
       	     HomePage => "https://web.stanford.edu/~chriseur"},
	    {Name => "Ritvik Ramkumar",
	     Email => "ritvik@math.berkeley.edu",
	     HomePage => "https://math.berkeley.edu/~ritvik"}
	    },
	Headline => "a package for computations with torus-equivariant formal spaces like toric varieties flag matroids",
	HomePage => "https://github.com/chrisweur/EquivariantLocalizations",
	PackageExports => {"Graphs","Matroids", "NormalToricVarieties"},	
	DebuggingMode => true
)
export {
	"TVariety",
	"tVariety",
    	"TKClass",
	"tKClass",
	"ampleTKClass",
	"TMap",
	"tMap",
	"pullback",
	"pushforward",	
	"diagonalTMap",
	"FlagMatroid",
	"flagMatroid",
	"tFlagVariety",
	"tFlagMap",
	"fourierMukai",
	"kTutte",
	"kCharPol",
	"hilb",
	"tvar",
	"charts",
	"monomialRing",
	"points",
	"ptsMap",
	"charRing",
	"matToIdeal",
	"HTpt",
	"tProjectiveSpace",
	"MomentGraph",
	"momentGraph",
	"affineToricRing",
	"isQuot",
	"constituents",
	"FlagMatroids",
	"makeCharRing",
	"makeHTpt",
	"tGeneralizedFlagVariety",
	"signedPermutations",
	"lieType"
}




------------------------------------------------------------------------------------------------
-------------------------------< internal auxiliary functions >---------------------------------
------------------------------------------------------------------------------------------------


---------------------< Laurent polynomial rings and monomial algebras >-------------------------

--input: a list L = {l_1, ... , l_d} of list of integers, or
--a matrix A whose columns are l_i's, representing exponents of a monomial map
--output: a quotient ring R/I, where R has variables x_1, ... x_d of degrees l_1, ... , l_d and
--I is the toric ideal defined by the monomial map
affineToricRing = method();
affineToricRing(List) := QuotientRing => L -> (
    d := #L;
    x := symbol x;
    R := QQ[x_1..x_d, Degrees => L];
    I := toricGroebner(transpose matrix L, R);
    R/I
    )

affineToricRing(Matrix) := QuotientRing => A -> affineToricRing(entries transpose A)

--internal auxiliary function:
--default Macaulay2 can't do fraction fields for Laurent rings
--but by shifting so that we exit Laurent rings and then going back, we can.
--Here given two Laurent polynomials f,g and a ring S with Inverses=>false, outputs the ratio
--of f and g by multiplying both of them with a big enough monomial to make them polynomials
--the output is the ratio in the new ring S,
--and a function goBack which puts the element in the ring of f if the denominator is a monomial
toFraction = method();
toFraction(RingElement,RingElement,Ring) := (f,g,S) -> (
    R := ring f;
    if not R === ring g then << " the two polynomials live in different rings " << return error;
    if not (#gens R) == (#gens S) then << " the temporary ring is no good " << return error;
    Exps := -((transpose (exponents f | exponents g))/min);
    mult := product(#Exps, i -> R_i^(Exps_i));
    numer := sub(mult*f, apply(#(gens R), i -> R_i=>S_i));
    denom := sub(mult*g, apply(#(gens R), i -> R_i=>S_i));
    rat := numer / denom;
    goBack := ratFct -> (
	N := numerator ratFct;
	D := denominator ratFct;
	if not #(terms D) == 1 then << "denominator not a monomial" << return error;
	sub(N, apply(#(gens S), i -> S_i=>R_i))*(sub(D, apply(#(gens S), i -> S_i=>R_i)))^(-1)
	);
    {rat, goBack}
)


--------------------------------------< moment graphs >-----------------------------------------

makeHTpt = method()
makeHTpt(ZZ) := Ring => n -> (
    t := symbol t;
    QQ[t_0..t_(n-1)]
    )

--a MomentGraph G is a MutableHashTable with the minimal data of:
--G.vertices : a list representing vertices of the graph G
--G.edges : a hash table whose keys are pairs {p,q} of vertices and values v are directed weights
-- of the edge  p --> q where v is a list of numbers such that matrix{v} * basis(1,G.HTpt) gives the weight
--G.HTpt : a polynomial ring, represent the T-equivariant cohomology ring of a point


MomentGraph = new Type of MutableHashTable

MomentGraph.synonym = "moment graph"

globalAssignment MomentGraph
net MomentGraph := G -> net ofClass class G | " on " | toString(#G.vertices) | " vertices with " | toString(#G.edges) | " edges "

momentGraph = method()
momentGraph(List,HashTable,Ring) := MomentGraph => (V,E,H) -> (
    new MomentGraph from {
	symbol vertices => V,
	symbol edges => E,
	symbol HTpt => H,
	cache => new CacheTable
	}
    )

graph(MomentGraph) := Graph => opts -> G -> graph(G.vertices, keys G.edges, EntryMode => "edges")


--------------------------------------< T-varieties >-------------------------------------------


--for setting up a character ring: given n, outputs the character ring of T = (kk^*)^n
makeCharRing = method();
makeCharRing(ZZ) := Ring => n -> (
    T := symbol T;
    ZZ[T_0..T_(n-1), MonomialOrder => GLex, Inverses=>true]
)


--a TVariety X is a HashTable with minimal data of:
--X.points : a list representing torus-invariant points
--X.charRing : a ring representing the character ring of the torus
--additionally, a TVariety X can have:
--X.charts : a hash table whose keys are X.points and values are (negative of) the characters 
--of the affine chart at the point
--X.momentGraph : a MomentGraph which is the moment graph of the T-variety
TVariety = new Type of MutableHashTable

TVariety.synonym = "T-variety"

globalAssignment TVariety
net TVariety := X -> net ofClass class X | " with an action of a " | toString(#gens X.charRing) | "-dimensional torus"


tVariety = method()

--a list L representing the torus-fixed points, and a character ring R defines a TVariety
tVariety(List, Ring) := TVariety => (L,R) -> (
    new TVariety from {
	symbol points => L,
	symbol charRing => R,
	cache => new CacheTable
	}
    )


--tVariety created from G, a moment graph, and a character ring R compatible with G.HTpt
tVariety(MomentGraph,Ring) := TVariety => (G,R) -> (
    if not #(gens R) == #(gens G.HTpt) then (
	<< "HTpt not compatible with the character ring" <<
	return error
	);
    new TVariety from {
	symbol points => G.vertices,
	symbol charRing => R,
	symbol momentGraph => G,
	cache => new CacheTable
	}
    )


--tVariety created from a moment graph G
--the character ring is created from G.HTpt
tVariety(MomentGraph) := TVariety => G -> (
    R := makeCharRing #(gens G.HTpt);
    tVariety(G,R)
    )


--returns the moment graph of the T-variety X if it is defined
momentGraph(TVariety) := MomentGraph => X -> (
    if X.?momentGraph then X.momentGraph
    else << "no moment graph defined for this T-variety" << return error
    )


--given TVariety X with X.momentGraph undefined, sets a moment graph G to be the
--moment graph of X, granted that the two sanity checks (charRing dimension, fixed points) work out
momentGraph(TVariety,MomentGraph) := (X,G) -> (
    if X.?momentGraph then (
	<< "moment graph already defined for this T-variety" <<
	return error
	);
    if #(gens X.charRing) != #(gens G.HTpt) then (
	<< "HTpt not compatible with the character ring" <<
	return error
	);
    if not G.vertices === X.points then (
	<< "the torus-fixed points are not compatible" <<
	return error
	);
    X.momentGraph = G;
    )


--tVariety created from list L of points and corresponding list M of their charts' characters,
--and R the character ring of the torus
tVariety(List,List,Ring) := TVariety => (L,M,R) -> (
    new TVariety from {
	symbol points => L,
	symbol charts => hashTable apply(#L, i -> (L_i,M_i)),
	symbol charRing => R,
	cache => new CacheTable 
    	}
    )

--given a TVariety X, whose X.charts have not been defined yet,
--and a list L = {l_1, ... , l_m} where l_i is a list of characters of the T-action
--at the affine chart around p_i where X.points = {p_1, ... , p_m}
--defines X.charts to be the hash table whose keys are X.points and values the characters
charts = method()

charts(TVariety) := X -> (
    if X.?charts then X.charts
    else << "no charts defined for this T-variety" << return error
    )

charts(TVariety,List) := (X,L) -> (
    if X.?charts then (
	<< "charts already defined for this T-variety" <<
	return error
	);
    if not #X.points == #L then (
	<< "number of charts in the list not equal to number of points" <<
	return error
	);
    X.charts = hashTable apply(#X.points, i -> (X.points_i,L_i))
    )



--internal auxiliary function: 
--input: a Laurent polynomial f and a TVariety X
--output: a Laurent polynomial f considered as an element of X.charRing
toCharRing = (X,f) -> (
    if f == 1 then return 1_(X.charRing);
    R := ring f; n := #(gens R);
    if not #(gens X.charRing) == n then
        << "rings have different number of variables" << return error;
    sub(f,apply(n, i -> R_i=>X.charRing_i))    
)


--projective space PP^n as a T=(k^*)^(n+1) variety, where (t_0, ... , t_n) acts on the
--coordinates [x_0, ... , x_n] by [t_0^(-1)x_0, ... , t_n^(-1)x_n]
--input: an integer n and the character ring R of T
tProjectiveSpace = method()
tProjectiveSpace(ZZ,Ring) := TVariety => (n,R) -> (
    V := apply(n+1, i -> set {i});
    E := hashTable apply(subsets(V,2), i -> 
	({i_0, i_1}, setIndicator(i_1,n+1) - setIndicator(i_0,n+1))
	);
    t := symbol t; H := QQ[t_0..t_n];
    G := momentGraph(V,E,H);
    X := tVariety(G,R);
    L := apply(V, v -> (select(V, w -> w =!= v))/(w -> setIndicator(w,n+1) - setIndicator(v,n+1)));
    charts(X,L);
    X.cache.ampleTKClass = tKClass(X, (X.points)/(i -> R_(setIndicator(i,n+1))));
    X
    )

--when only given an integer n
tProjectiveSpace(ZZ) := TVariety => n -> (
    R := makeCharRing(n+1);
    tProjectiveSpace(n,R)
    )


--product of two TVarieties X,Y with an action of a common torus T
--the product is endowed with the diagonal action of T
TVariety ** TVariety := TVariety => (X,Y) -> (
    R := X.charRing;
    if not R === Y.charRing then << "character rings need be same" << return error;
    L := elements ((set X.points) ** (set Y.points));
    XxY := tVariety(L,R);
    if X.?charts and Y.?charts then (
	M := apply(L, l -> (X.charts)#(first l) | (Y.charts)#(last l));
	charts(XxY,M);
	);
    XxY
    --TODO: if both has moment graphs, then should also compute the moment graph
)

--the product function above does NOT automatically compute the product moment graph
MomentGraph ** MomentGraph := MomentGraph => (G1,G2) -> (
    if G1.HTpt =!= G2.HTpt then (
	<< " the two HTpt are different " <<
	return error
	);
    H := G1.HTpt;
    V := (elements((set G1.vertices) ** (set G2.vertices)))/splice;
    E1 := flatten apply(G2.vertices, q -> (keys G1.edges)/(k -> ({(k_0,q), (k_1,q)}, G1.edges#k)));
    E2 := flatten apply(G1.vertices, p -> (keys G2.edges)/(k -> ({(p,k_0), (p,k_1)}, G2.edges#k)));
    mixedCand := select(elements ((set keys G1.edges) ** (set keys G2.edges)), i -> 
	rank matrix {G1.edges#(i_0), G2.edges#(i_1)} < 2);
    mixedE := apply(mixedCand, i -> (
	    char1 := G1.edges#(i_0);
	    char2 := G2.edges#(i_1);
	    primitive := char1 // (gcd char1);
	    firsts := {first select(char1, i -> i != 0), first select(char2, i -> i != 0)};
	    g := gcd (firsts/(i -> i / first select(primitive, i -> i!= 0)));
	    trueChar := g * primitive;
	    if firsts_0 * firsts_1 > 0 then 
	    ({(first i_0, first i_1), (last i_0, last i_1)}, trueChar)
	    else ({(first i_0, last i_1), (last i_0, first i_1)}, trueChar)
	    )
	);
    momentGraph(V, hashTable (E1 | E2 | mixedE), H)	    
    )




--Given a list L of characters of torus of X, outputs the numerator in the Hilbert series
--of the associated monomial subalgebra
tHilbNumer = method();
tHilbNumer(TVariety,List) := RingElement => (X,L) -> (
    if L == {} then return toCharRing(X,1);
    R := monomialRing(L);
    I := matToIdeal transpose matrix L;
    f := value numerator hilbertSeries (map(R,ring I,gens R))I;
    toCharRing(X,f)
)




--a TKClass C has data of:
--C.tvar = a TVariety X that the T-equiv K-class C lives on
--C.hilb = a hash table whose keys are points of X and values are the Hilbert series at the point
TKClass = new Type of HashTable

TKClass.synonym = "equivariant K-class"

globalAssignment TVariety
net TKClass := C -> net ofClass class C | " on a T-variety "


--a TKClass is given by a TVariety X and a list L of Laurent polynomials for each torus-invariant
--points in X, (listed in the order of X.points)
tKClass = method();
tKClass(TVariety,List) := TKClass => (X,L) -> (
    K := X.points;
    if any(L, l -> ring l =!= X.charRing) then L = L/(f -> toCharRing(X,f));
    new TKClass from {
	symbol tvar => X,
	symbol hilb => hashTable apply(#K, i -> (K_i,L_i))
    }
)

tVariety(TKClass) := TVariety => C -> C.tvar


--tests whether a TKClass satisfies the edge-compatibility criterion
isWellDefined(TKClass) := Boolean => C -> (
    X := C.tvar;
    if not X.?momentGraph then (
	<< "a moment graph needs to be defined for this T-variety" <<
	return error
	);
    G := X.momentGraph;
    R := X.charRing;
    x := symbol x;
    S := QQ[x_0..x_(#gens R - 1)];
    badEdges := select(keys G.edges, e -> (
	    pt1 := first e;
	    pt2 := last e;
	    lambda := G.edges#e;
	    ratio := toFraction(C.hilb#pt1 - C.hilb#pt2,  1 - R_lambda, S);
	    #(terms(QQ,denominator first ratio)) != 1
	    )
	);
    if #badEdges != 0 then (
	<< "incompatible edges " | toString(badEdges) <<
	return false
	);
    true
    )


--the trivial TKClass (where X^T --> R is a constant 1 function) of a TVariety X
--in other words, the TKClass of the structure sheaf of X
trivialTKClass = method();
trivialTKClass(TVariety) := TKClass => X -> (
    L := apply(X.points, p -> 1_X.charRing);
    tKClass(X,L)
)


--multiplying two TKClasses
TKClass * TKClass := (C1,C2) -> (
    X1 := C1.tvar; X2 := C2.tvar;
    if not X1 === X2 then << "the T-varieties are different" << return error;
    L := apply(X1.points, p -> C1.hilb#p * C2.hilb#p);
    tKClass(X1,L)
)

TKClass ^ ZZ := (C,d) -> (
    if d > 0 then return product(d, i -> C)
    else if d == 0 then return trivialTKClass C.tvar
    else if d < 0 then (
	if not all(values C.hilb, f -> 1 == #terms f) then (
	    << "the TKClass is not a line bundle" <<
	    return error
	    );
	L := apply(C.tvar.points, p -> (C.hilb#p)^(-1));
	Cneg := tKClass(C.tvar,L);
	return product(-d, i -> Cneg)
	)
    )


--adding two TKClasses
TKClass + TKClass := (C1,C2) -> (
    X1 := C1.tvar; X2 := C2.tvar;
    if not X1 === X2 then << "the T-varieties are different" << return error;
    L := apply(X1.points, p -> C1.hilb#p + C2.hilb#p);
    tKClass(X1,L)
)

--if a TVariety X has a distinguished O(1) T-equivariant line bundle, then returns its TKClass
ampleTKClass = method();
ampleTKClass(TVariety) := TKClass => X -> (
    if X.cache.?ampleTKClass then return X.cache.ampleTKClass
    else << "no distinguished ample line bundle on this T-variety" << return error;
)


--if a TVariety X does not have an ample class defined, and C is a TKClass on X, 
--sets the ampleTKClass of X to be C
ampleTKClass(TVariety,TKClass) := (X,C) -> (
    if X.cache?ampleTKClass then (
	<< "an ampleTKClass already defined for this T-variety" <<
	return error
	);
    if C.tvar =!= X then << "not a TKClass of this T-variety" << return error;
    X.cache.ampleTKClass = C
    )


--a TMap f has data of:
--f.source: the source tVariety X,
--f.target: the target tVariety Y
--f.ptsMap: a hash table whose keys are X.points and values are the point Y.points that it maps to 
TMap = new Type of HashTable

TMap.synonym = "T-equivariant map"

globalAssignment TMap
net TMap := phi -> net ofClass class phi | " of T-varieties "



--a TMap is given by providing the source X and target Y and a list L of pairs (X point, Y point)
tMap = method();
tMap(TVariety,TVariety,List) := TMap => (X,Y,L) -> (
    if not X.charRing === Y.charRing then << "character rings need be same" << return error;
    new TMap from {
	symbol source => X,
	symbol target => Y,
	symbol ptsMap => hashTable L,
	cache => new CacheTable	
    }
)

--pullback map of TKClasses given a TMap
pullback = method();
pullback(TMap) := FunctionClosure => phi -> (
    X := phi.source; 
    Y := phi.target;
    if not phi.cache.?pullback then phi.cache.pullback = C -> (
	if C.tvar =!= Y then (
	    << "the TKClass to pullback is not a TKClass of the target T-variety" <<
	    return error
	    );
	L := apply(X.points, p -> C.hilb#((phi.ptsMap)#p));
	tKClass(X,L)
    );
    phi.cache.pullback
)

--given a TMap, computes the pushforward map as a function
pushforward = method();
pushforward(TMap) := FunctionClosure => phi -> (
    if phi.cache.?pushforward then return phi.cache.pushforward;
    X := phi.source;
    Y := phi.target;
    R := X.charRing;
    Ydenoms := hashTable apply(Y.points, q -> (q, product((Y.charts)#q, l -> 1-R_l)));
    Xdenoms := hashTable apply(X.points, p -> (p, product((X.charts)#p, l -> 1-R_l)));
    x := symbol x;
    S := QQ[x_0..x_(#(gens R)-1)];
    pushforwardFct := C -> (
	if not C.tvar === X then << "TKClass not of the source T-variety" << return error;
	L := apply(Y.points, q -> (
	    	preimages := select(X.points, p -> (phi.ptsMap)#p === q);
	    	if #preimages == 0 then return 0_R;
	    	Ydenom := Ydenoms#q;
	    	toSum := apply(preimages, p -> toFraction(Ydenom * C.hilb#p, Xdenoms#p, S));
	    	val := (last first toSum) sum(toSum/first)
	    	)
	    );
	tKClass(Y,L)
    	);
    phi.cache.pushforward = pushforwardFct
    )


--given a TVariety X outputs the diagonal map X -> X x X
diagonalTMap = method();
diagonalTMap(TVariety) := TMap => X -> (
    Y := X ** X;
    ptPairs := apply(X.points, p -> (
	Q := first select(Y.points, q -> (first q) === (last q) and (first q) === p);
	(p,Q)
	)
    );
    tMap(X,Y,ptPairs)
)



--given two maps, takes Cartesian product of them
TMap ** TMap := TMap => (phi,psi) -> (
    X := phi.source ** psi.source;
    Y := phi.target ** psi.target;
    ptPairs := apply(X.points, p -> (
	Q := ((phi.ptsMap)#(first p),(psi.ptsMap)#(last p));
	(p,Q)
	)
    );
    tMap(X,Y,ptPairs)
)


--composition f o g of two TMaps g: X --> Y, f: Y --> Z;
compose(TMap,TMap) := TMap => (f,g) -> (
    if not f.source === g.target then << "did you mean to switch the order?" << return error;
    Y := f.target; X := g.source;
    ptPairs := apply(X.points, p -> (p, f.ptsMap#(g.ptsMap#p)));
    tMap(X,Y,ptPairs)
    )

-------------------------------------------------------------------------------------------------
--------------------------------< generalized flag varieties >-----------------------------------
-------------------------------------------------------------------------------------------------


---------< internal auxiliary functions: signed subsets, flags, and indicator vectors >----------

--makes a string "n*" given a positive integer n
astrsk = n -> toString(n) | "*"

--given either integer n or "n*", outputs n
unastrsk = i -> if instance(i,String) then value first i else if instance(i,ZZ) then i else error

--given a set s consisting of elements e where e is an integer i or "i*" with 0 <= i <= n-1
--outputs the signed indicator vector
setIndicator = (s,n) -> (
    if (elements s)/unastrsk != unique (elements s/unastrsk) then (
	<< " the signed subset is not admissible " <<
	return error
	);
    apply(n, i -> (
	    if member(i,s) then 1
    	    else if member(astrsk i, s) then -1
    	    else 0
    	    )
	)
    )

--given a list of integers of length n, outputs the corresponding flag of signed subsets
vecToFlag = v -> sort apply(max (v/abs), i -> (
	supp := positions(v, j -> abs j > i);
	set apply(supp, j -> if v_j > 0 then j else astrsk j)
	)
    )

--likewise, but applying "unique"
redVecToFlag = v -> unique vecToFlag v

flagToVec = (L,n) -> sum(L, s -> setIndicator(s,n))


--all signed permutations of a list
--allows for repeated entries, just like the ordinary "permutations" function
signedPermutations = L -> (
    if #L == 1 then {{first L}, {- first L}} 
    else flatten apply(#L, i -> flatten apply(signedPermutations(drop(L,{i,i})), j -> {j | {L_i}, j | {-L_i}})
	)
    )

--all even signed permutations (i.e. signed permutations with same parity of minus signs)
--again, allows for repeated entries, like ordinary "permutations" and "signedPermutations"
evenSignedPermutations = L -> (
    SP := signedPermutations L;
    if any(L, i -> i == 0) then SP
    else (
	parity := mod(#select(L, i -> i < 0),2);
	select(SP, l -> mod(#select(l, i -> i < 0),2) == parity)
	)
    )
 
---------------------< internal auxiliary functions: roots and weights >-------------------------


--internal auxiliary functions for tGeneralizedFlagVariety
--given a classical Lie type LT, the root system dimension d, and list L = {l_1, ... , l_m},
--outputs the highest weight vector w_(l_1) + ... + w_(l_m) where w_i's are fundamental weights
--(w_d in the orthogonal case ("B" and "D"), strictly speaking we are using
--twice of the fundamental weight)
highestWeight := (LT,d,L) -> (
    if LT == "A" then n := d+1 else n = d;
    if member(LT,{"A","C"}) or (LT == "B" and not member(d,L)) then
    sum(L, i -> setIndicator(set apply(i, j -> j),n))
    else if LT == "B" and member(d,L) then (
	hw := sum(L, i -> (
		if i < d then setIndicator(set apply(i, j -> j),n)
		else if i == d then 1/2 * setIndicator(set apply(i, j -> j),n)
		)
	    );
	if all(hw, i -> liftable(i,ZZ)) then hw/(i -> lift(i,ZZ))
	else << " spin groups not implemented yet " << return error
	)
    else if LT == "D" then (
	hw = sum(L, i -> (
		if i < d-1 then setIndicator(set apply(i, j -> j),n)
		else if i == d then 1/2 * setIndicator(set apply(d, j -> j),n)
		else if i == d-1 then 1/2 * setIndicator(set (apply(d-1, j -> j) | {astrsk(d-1)}),n)
		)
	    );
	if all(hw, i -> liftable(i,ZZ)) then hw/(i -> lift(i,ZZ))
	else << " spin groups not implemented yet " << return error
	)
    )

--the Weyl group orbit of the highest weight of (LT,d,L) with notation as above
extremalWeights := (LT,d,L) -> (
    lambda := highestWeight(LT,d,L);
    if LT == "A" then unique (permutations lambda)
    else if member(LT,{"B","C"}) then unique (signedPermutations lambda)
    else if LT == "D" then unique (evenSignedPermutations lambda)
    )

--given a classical Lie type LT, outputs a function f where, given a list v representing
--a nonzero vector, f outputs {v / (abs gcd v)}, that is, a root if v is a (positive)
-- multiple of a root, and f(v) = {} otherwise
toRoot := LT -> (
    if member(LT,{"A","D"}) then (
	f := v -> (
	    non0s := select(v, i -> i != 0);
	    if #non0s == 2 and abs first non0s == abs last non0s then {v // (abs gcd v)} else {}
	    )
	)
    else if LT == "B" then (
	f = v -> (
	    non0s := select(v, i -> i != 0);
	    if #non0s == 1 or (#non0s == 2 and abs first non0s == abs last non0s) then
	    {v // (abs gcd v)}
	    else {}
	    )
	)
    else if LT == "C" then (
	f = v -> (
	    non0s := select(v, i -> i != 0);
	    if #non0s == 1 then {2 * (v // (abs gcd v))}
	    else if (#non0s == 2 and abs first non0s == abs last non0s) then {v // (abs gcd v)}
	    else {}
	    )
	)
    )


--input: LT, d, L
--a string LT which is "A", "B", "C", or "D", representing the classical Lie types,
--(we follow the convention in Example 3.4 of https://arxiv.org/pdf/1904.11029.pdf
--for the ordering of simple roots and fundamental weights)
--an integer d, representing the dimension of the root system,
--(we do *not* check the low d isogenies,
--for example, A_3 = D_3 but the code will not recognized this and output different things)
--a list L of integers each ranging from 1 to d.
--output:
--a generalized flag variety G/P as a T-variety with charts,
--where G is the classical Lie group of type LT with an action of a d-torus T,
--(except in the case of "A", we let T be the (d+1)-torus by *not* projectivizing the torus)
--and P is the parabolic subgroup corresponding to W_([d]\L)
--that is, subgroup of the Weyl group generated by elements *not* in L
--the ample class is defined to be embedding of G/P coming from the representation of G
--whose highest weight vector equals sum(L, i -> w_i) where w_i is the i-th fundamental weight
--(except in the orthogonal case "B,D", the "half"-fundamental weights are doubled
--that is, we are not considering the Spin representations but representations of SO(n).
tGeneralizedFlagVariety = method()
tGeneralizedFlagVariety(String,ZZ,List) := TVariety => (LT,d,L) -> (
    if not member(LT,{"A","B","C","D"}) then (
	<< " the first entry must be one of \"A\", \"B\", \"C\", or \"D\" " <<
	return error
	);
    if d <= 0 then (
	<< " the second entry (dimension) must be a positive integer " <<
	return error
	);
    if not all(L, i -> 0 <= i and i <= d+1) then (
	<< " indices for the weights must be between 1 and the dimension (inclusive) " <<
	return error
	);
    toRootFunc := toRoot LT;
    R := if LT == "A" then makeCharRing(d+1) else makeCharRing d;
    extrWts := extremalWeights(LT,d,L);
    GEdgesDouble := new MutableHashTable;
    chrts := apply(extrWts, v -> (
	    lambdas := {};
	    apply(delete(v,extrWts), w -> (
		    lambda := toRootFunc(w-v);
		    if #lambda == 1 then (
			lambdas = lambdas | lambda;
			GEdgesDouble#({v,w}/redVecToFlag) = first lambda;
			)
		    )
		);
	    lambdas
	    )
	);
    X := tVariety(extrWts/redVecToFlag, chrts, R);
    GEdges := hashTable apply(unique ((keys GEdgesDouble)/set), i -> (
	    e := elements i;
	    (e, GEdgesDouble#e)
	    )
	);
    H := if LT == "A" then makeHTpt(d+1) else makeHTpt d;
    G := momentGraph(X.points, GEdges, H);
    momentGraph(X,G);
    X.cache.ampleTKClass = tKClass(X, apply(extrWts, i -> R_i));
    X.cache.lieType = LT;
    X
    )

--same as tGeneralizedFlagVariety but with the ring R provided for the character ring.
tGeneralizedFlagVariety(String,ZZ,List,Ring) := TVariety => (LT,d,L,R) -> (
    X := tGeneralizedFlagVariety(LT,d,L);
    S := X.charRing;
    if #(gens R) != #(gens S) then << " check character ring " << return error;
    conversion := map(R,S,gens R);
    X.charRing = R;
    C := ampleTKClass X;
    X.cache.ampleTKClass = tKClass(X, apply(X.points, i -> conversion C.hilb#i));
    X
    )

lieType = method()
lieType(TVariety) := String => X -> (
    if X.cache.?lieType then X.cache.lieType
    else << " no Lie Type defined for this T-variety " << return error
    )


--------------------------------< ordinary flag varieties >-----------------------------------


--swaps the (l_0,l_1)th places in the vector v
swap = (v,l) -> apply(#v, i -> 
    if i == first l then v_(last l)
    else if i == last l then v_(first l)
    else v_i
)


--converts a pair s into a length n list where s_0 has -1 and s_1 has 1 and 0 everywhere else
swapIndicator = (s,n) -> (
    apply(n, i -> 
	if i == first s then -1
	else if i == last s then 1
	else 0
    )
)



--Given a list K = {k_1, ... , k_m} and a number n defining flag variety Fl(K;n) consisting of
--flags of linear subspaces of kk^n of dimensions k_1, ... , k_m, returns the TVariety where
--the action of T = (kk^*)^n on the vector space kk^n is (t.v) = (t^-1v)
tFlagVariety = method();
tFlagVariety(List,ZZ,Ring) := TVariety => (K,n,R) -> (
    if not #(gens R) == n then << "check character ring" << return error;
    if not max K < n then << "check rank sequence K" << return error;
    E := set toList(0..(n-1));
    pts := (unique permutations sum(K/(k -> toList(k:1) | toList(n-k:0))))/vecToFlag;
    chrts := apply(pts, p -> (toList sum(p, l -> l**(E-l)))/(s -> swapIndicator(s,n)));
    X := tVariety(pts,chrts,R);
    L := apply(X.points, p -> (Exps := flagToVec(p,n); product(#Exps, i -> R_i^(Exps_i))));
    X.cache.ampleTKClass = tKClass(X,L);
    X
)


--if one does not want to make the charRing beforehand.
--NOT recommended for use...
tFlagVariety(List,ZZ) := TVariety => (K,n) -> tFlagVariety(K,n,makeCharRing n)



--Given two lists Kso, Kta (for rank sequences of source and target flag varieties) and n,
--creates the two TVarieties and makes a TMap between them (given the charRing R).
tFlagMap = method();
tFlagMap(List,List,ZZ,Ring) := TMap => (Kso,Kta,n,R) -> (
    Flso := tFlagVariety(Kso,n,R);
    Flta := tFlagVariety(Kta,n,R);
    ptPairs := apply(Flso.points, p -> (p,first select(Flta.points, q -> isSubset(q,p))));
    tMap(Flso,Flta,ptPairs)
)

--if X and Y are already tFlagVarieties, then the following outputs the corresponding tFlagMap
-- X --> Y
tFlagMap(TVariety,TVariety) := TMap => (X,Y) -> (
    if not X.charRing === Y.charRing then << "character ring need be same" << return error;
    ptPairs := apply(X.points, p -> (p,first select(Y.points, q -> isSubset(q,p))));
    tMap(X,Y,ptPairs)
)


----------------------------------< ordinary flag matroids >--------------------------------------

FlagMatroid = new Type of HashTable

FlagMatroid.synonym = "flag matroid"

globalAssignment FlagMatroid
net FlagMatroid := M -> net ofClass class M | " with rank sequence " | toString((M.constituents)/rank) | " on " | toString(#M.groundSet) | " elements "


flagMatroid = method();

--Given a list L of concordant matroids (M_1, ... , M_k) returns the flag matroid object
--Convention: M_i is quotient of M_(i+1)
--Does not check concordance of matroids in the list, but checks same cardinality of ground set.
flagMatroid(List) := FlagMatroid => L -> (
    E := (first L).groundSet; n := #E;
    if any(L, m -> not #m.groundSet == n) then << "ground set not all same size" << return error;
    new FlagMatroid from {
	symbol groundSet => E,
	symbol constituents => L,
	cache => new CacheTable
    }
)

--Given l x n matrix A and a list r of ranks, outputs the associated flag matroid
flagMatroid(Matrix,List) := FlagMatroid => (A,r) -> (
    k := #r; l := numcols A;
    if r == {} or any(k-1, i -> r_i > r_(i+1)) or r_(k-1) > l then << "check rank sequence" << return error;
    ML := apply(k, i -> matroid A^(apply(r_i, j -> j)) );
    flagMatroid ML
)

--checks that the constituents of a flag matroid M are concordant
isWellDefined(FlagMatroid) := Boolean => M -> (
    L := M.constituents; k := #L;
    all(k-1, i -> isQuot(L_i,L_(i+1))) 
)

--for a flag matroid F, outputs a list of chains of bases of the constituent matroids
bases(FlagMatroid) := List => M -> (
    if not M.cache.?bases then M.cache.bases = (
	ML := M.constituents; k := #ML;
	BL := flatten apply(k, i -> (bases ML_i)/(b -> (i,b)) );
	rel := (a,b) -> first a < first b and isSubset(last a, last b);
	P := poset(BL, rel , AntisymmetryStrategy => "none");
	(maximalChains P)/(c -> c/last)
    );
    M.cache.bases
)


--computes the lattice points of the base polytope of a flag matroid M
latticePts = method();
latticePts(FlagMatroid) := M -> (
    n := #M.groundSet;
    BL := M.constituents/bases/(B -> B/(b -> setIndicator(b,n)));
    k := #BL;
    unique apply((k:0)..toSequence(BL/(B -> #B-1)), i -> sum(k, j -> (BL_j)_(i_j)))
)


--direct sum, deletion, restriction, and contraction of a flag matroid is done by doing
--respective operation on the operation on each constituents
FlagMatroid ++ FlagMatroid := FlagMatroid => (M,N) -> (
    ML := M.constituents; NL := N.constituents;
    if not #ML == #NL then << "two flag matroids have different number of constituents" << return error;
    flagMatroid apply(#ML, i -> ML_i ++ NL_i)
)

restriction(FlagMatroid,Set) := FlagMatroid => (M,S) -> (
    flagMatroid(M.constituents/(m -> restriction(m,S)))
)

restriction(FlagMatroid,List) := FlagMatroid => (M,L) -> (
    flagMatroid(M.constituents/(m -> restriction(m,L)))
)

contraction(FlagMatroid,Set) := FlagMatroids => (M,S) -> (
    flagMatroid(M.constituents/(m -> contraction(m,S)))
)

contraction(FlagMatroid,List) := FlagMatroids => (M,L) -> (
    flagMatroid(M.constituents/(m -> contraction(m,L)))
)

deletion(FlagMatroid,Set) := FlagMatroid => (M,S) -> (
    flagMatroid(M.constituents/(m -> deletion(m,S)))
)

deletion(FlagMatroid,List) := FlagMatroid => (M,L) -> (
    flagMatroid(M.constituents/(m -> deletion(m,L)))
)

FlagMatroid | Set := (M,S) -> restriction(M,S)
FlagMatroid \ Set := (M,S) -> deletion(M,S)
FlagMatroid / Set := (M,S) -> contraction(M,S)
FlagMatroid | List := (M,L) -> restriction(M,L)
FlagMatroid \ List := (M,L) -> deletion(M,L)
FlagMatroid / List := (M,L) -> contraction(M,L)


dual(FlagMatroid) := FlagMatroid => {} >> opts -> M -> (
    ML := M.constituents;
    flagMatroid apply(reverse ML, m -> dual m)
)



face(Matroid,Set) := (M,S) -> (M | S) ++ (M / S)

face(FlagMatroid,Set) := (M,S) -> (M | S) ++ (M / S)


--rank (of a subset) in a flag matroid
rank(FlagMatroid) := ZZ => M -> sum(M.constituents/rank)

rank(FlagMatroid,Set) := ZZ => (M,A) -> sum(M.constituents, m -> rank(m,A))






------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

-*--- commented out for now
beginDocumentation()

-- Documentation --
-- <<docTemplate
doc ///
	Key
		EquivariantLocalizations
	Headline
		a package for computations with flag matroids and equivariant localization
	Description
		Text
			Define in words T-Varieties and equivariant localization......

			This Macaulay2 package is designed to .....

			References.....
			

///


doc ///
	Key
		TVariety
	Headline
		the class of all T-varieties
	Description
		Text
			To see how to specify a T-variety, see @TO tVariety@.

			Describe basic functionality of the package...
		
		Example
			Here....

///


doc ///
	Key
		tVariety
		(tVariety, List, HashTable, List, Ring)
	Headline
		constructs a T-variety
	Usage
		X = tVariety(P,T,L,R)
	Inputs
		P:List
			of Torus fixed points
		T:HashTable
			encoding the one-dimensional Torus fixed orbits.
			The values are the orbits and the corresponding key is the pair
			of Torus fixed points in the orbit
		L:List
			of lists; each entry consists of a Torus fixed point along with
			the characters of the contracting affine chart around it
		R:Ring
			representing the characteristic ring the torus
	Outputs
		X:TVariety
	Description
		Text
			Here..
			
		Example
			Here...

	Caveat
		This function does not check if X defines a T-variety - see 
		@TO2{(isWellDefined, TVariety), "isWellDefined"}@.
	
	SeeAlso
		(isWellDefined, TVariety)
		(symbol **, TVariety, TVariety)
		tFlagVariety
		tMap
///


doc ///
	Key
		(symbol **, TVariety, TVariety)
	Headline
		product of T-varieties
	Usage
		X ** Y
	Inputs
		X:TVariety
		Y:TVariety
	Outputs
		X:TVariety
		    product of X and Y
	Description
		Text
			Here..
			
		Example
			Here...

	Caveat
		This function does not check if X defines a T-variety - see 
		@TO2{(isWellDefined, TVariety), "isWellDefined"}@.
	
	SeeAlso
		(isWellDefined, TVariety)
///


doc ///
	Key
		TKClass
	Headline
		a type of HashTable
	Description
		Text
			Describe it...
			
	SeeAlso
	    

///


doc ///
	Key
		tKClass
		(tKClass, TVariety, List)
	Headline
		constructs a equivariant K-class
	Usage
		C = tKClass(X,L)
	Inputs
		X:TVariety
		L:List
			of Laurent polynomials corresponding to each T-invariant point
	Outputs
		C:TKClass
	Description
		Text
			Here..
			
		Example
			Here...

	Caveat
		This function does not check if X defines a T-variety - see 
		@TO2{(isWellDefined, TKClass), "isWellDefined"}@.
	
	SeeAlso
		(isWellDefined, TKClass)
		(symbol *, TKClass, TKClass)
		(symbol +, TKClass, TKClass)
		assignAmpleTKClass
		pullback
		pushforward
///


---*-


end







---------------------------------------------------------------------------------------------
-----------------------------< some tests while developing >---------------------------------
---------------------------------------------------------------------------------------------

----------< tGeneralizedFlagVariety tests >-------------
restart
needsPackage "GKMManifolds"

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

--if a character ring is pre-determined
R = makeCharRing 3
X = tGeneralizedFlagVariety("A",2,{1,2},R)
C = ampleTKClass X
ring first values C.hilb === R
peek C
isWellDefined C


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

--isotropic Grassmannian(1,2;6) (i.e. SpGr(1,2;6))
X = tGeneralizedFlagVariety("C",3,{1,2})
peek X
H = X.charts
netList {(first keys H), H#(first keys H)}
G = momentGraph X
peek G
G.edges
C = ampleTKClass X
peek C
isWellDefined C


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

--we can still do the double and consider SOGr(3,7) which is fine
X = tGeneralizedFlagVariety("B",3,{3,3})
peek X
H = X.charts
G = momentGraph X
peek G
G.edges
C = ampleTKClass X
peek C
isWellDefined C



--low d isogenies A_3 = D_3
--SOGr(3,6) should look similar to P3^* = Gr(3,4)
X = tGeneralizedFlagVariety("D",3,{3})
peek X
--SOGr(2,6) should look similar to P3^* = Gr(3,4)
X = tGeneralizedFlagVariety("D",3,{2})
peek X
--SOGr(1,6) should look similar to Gr(2,4)
X = tGeneralizedFlagVariety("D",3,{1})
peek X


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
needsPackage "GKMManifolds"

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



--a sanity check with projective space P^3
P3 = tProjectiveSpace 3
R = P3.charRing;
describe R
charts P3
G = momentGraph P3
G.edges
peek G
graph G

C = ampleTKClass P3
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