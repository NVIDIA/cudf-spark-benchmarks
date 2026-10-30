SELECT 
    N.n_name,
    R.r_name,
    SUM(L.l_extendedprice * (1 - L.l_discount)) AS total_revenue
FROM 
    lineitem L
JOIN 
    orders O ON L.l_orderkey = O.o_orderkey
JOIN 
    customer C ON O.o_custkey = C.c_custkey
JOIN 
    nation N ON C.c_nationkey = N.n_nationkey
JOIN 
    region R ON N.n_regionkey = R.r_regionkey
WHERE 
    O.o_orderdate >= DATE '1997-01-01' AND O.o_orderdate < DATE '1998-01-01'
GROUP BY 
    N.n_name, R.r_name
ORDER BY 
    total_revenue DESC
LIMIT 10;