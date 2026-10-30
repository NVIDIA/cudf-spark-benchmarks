SELECT 
    P.p_name,
    S.s_name,
    SUM(L.l_quantity) AS total_quantity,
    AVG(L.l_extendedprice) AS avg_price,
    MAX(L.l_discount) AS max_discount,
    MIN(L.l_tax) AS min_tax,
    CONCAT('Region: ', R.r_name, ', Nation: ', N.n_name) AS location_info
FROM 
    part P
JOIN 
    partsupp PS ON P.p_partkey = PS.ps_partkey
JOIN 
    supplier S ON PS.ps_suppkey = S.s_suppkey
JOIN 
    lineitem L ON P.p_partkey = L.l_partkey
JOIN 
    orders O ON L.l_orderkey = O.o_orderkey
JOIN 
    customer C ON O.o_custkey = C.c_custkey
JOIN 
    nation N ON S.s_nationkey = N.n_nationkey
JOIN 
    region R ON N.n_regionkey = R.r_regionkey
WHERE 
    L.l_shipdate > '1996-01-01' AND 
    L.l_shipdate < '1997-01-01' AND 
    P.p_name LIKE '%brass%'
GROUP BY 
    P.p_name, S.s_name, R.r_name, N.n_name
ORDER BY 
    total_quantity DESC, avg_price ASC
LIMIT 10;