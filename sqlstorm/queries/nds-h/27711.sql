SELECT 
    P.p_name,
    S.s_name,
    C.c_name,
    COUNT(O.o_orderkey) AS total_orders,
    SUM(L.l_extendedprice * (1 - L.l_discount)) AS total_revenue,
    LEFT(R.r_name, 3) AS region_prefix,
    CONCAT(P.p_brand, ' ', P.p_type) AS full_part_description
FROM 
    part P
JOIN 
    partsupp PS ON P.p_partkey = PS.ps_partkey
JOIN 
    supplier S ON PS.ps_suppkey = S.s_suppkey
JOIN 
    nation N ON S.s_nationkey = N.n_nationkey
JOIN 
    region R ON N.n_regionkey = R.r_regionkey
JOIN 
    lineitem L ON P.p_partkey = L.l_partkey
JOIN 
    orders O ON L.l_orderkey = O.o_orderkey
JOIN 
    customer C ON O.o_custkey = C.c_custkey
WHERE 
    P.p_comment LIKE '%special%'
    AND O.o_orderdate >= DATE '1997-01-01'
GROUP BY 
    P.p_name, S.s_name, C.c_name, R.r_name, P.p_brand, P.p_type
ORDER BY 
    total_revenue DESC, total_orders DESC
LIMIT 10;