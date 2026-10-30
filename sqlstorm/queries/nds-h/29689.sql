SELECT 
    P.p_name AS part_name,
    S.s_name AS supplier_name,
    C.c_name AS customer_name,
    O.o_orderdate AS order_date,
    L.l_quantity AS quantity,
    L.l_extendedprice AS extended_price,
    R.r_name AS region_name,
    CASE 
        WHEN LENGTH(P.p_comment) > 20 THEN CONCAT(SUBSTRING(P.p_comment, 1, 20), '...')
        ELSE P.p_comment 
    END AS abbreviated_comment
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
    R.r_name LIKE 'N%'
    AND O.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
ORDER BY 
    R.r_name, O.o_orderdate DESC
LIMIT 100;