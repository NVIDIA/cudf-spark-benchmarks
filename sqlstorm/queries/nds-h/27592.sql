SELECT 
    P.p_name, 
    SUM(L.l_quantity) AS total_quantity, 
    AVG(L.l_extendedprice) AS avg_extended_price, 
    COUNT(DISTINCT O.o_orderkey) AS total_orders,
    R.r_name AS region_name,
    S.s_name AS supplier_name
FROM 
    part P
JOIN 
    lineitem L ON P.p_partkey = L.l_partkey
JOIN 
    orders O ON L.l_orderkey = O.o_orderkey
JOIN 
    partsupp PS ON P.p_partkey = PS.ps_partkey
JOIN 
    supplier S ON PS.ps_suppkey = S.s_suppkey
JOIN 
    nation N ON S.s_nationkey = N.n_nationkey
JOIN 
    region R ON N.n_regionkey = R.r_regionkey
WHERE 
    P.p_brand LIKE 'Brand#%'
    AND O.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
GROUP BY 
    P.p_name, R.r_name, S.s_name
HAVING 
    SUM(L.l_discount) > 0.05
ORDER BY 
    total_quantity DESC, avg_extended_price ASC;