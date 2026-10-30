SELECT 
    P.p_name AS part_name,
    CONCAT('Manufacturer: ', P.p_mfgr, ', Brand: ', P.p_brand, ', Type: ', P.p_type) AS part_details,
    S.s_name AS supplier_name,
    C.c_name AS customer_name,
    R.r_name AS region_name,
    O.o_orderstatus AS order_status,
    O.o_orderdate AS order_date,
    O.o_totalprice AS total_price,
    L.l_quantity AS quantity,
    L.l_extendedprice AS extended_price,
    L.l_discount AS discount,
    L.l_tax AS tax,
    LENGTH(P.p_comment) AS comment_length,
    TRIM(BOTH ' ' FROM P.p_comment) AS trimmed_comment
FROM 
    part P
JOIN 
    partsupp PS ON P.p_partkey = PS.ps_partkey
JOIN 
    supplier S ON PS.ps_suppkey = S.s_suppkey
JOIN 
    lineitem L ON S.s_suppkey = L.l_suppkey
JOIN 
    orders O ON L.l_orderkey = O.o_orderkey
JOIN 
    customer C ON O.o_custkey = C.c_custkey
JOIN 
    nation N ON S.s_nationkey = N.n_nationkey
JOIN 
    region R ON N.n_regionkey = R.r_regionkey
WHERE 
    P.p_name LIKE '%Widget%'
    AND O.o_orderdate > cast('1998-10-01' as date) - INTERVAL '1 year'
ORDER BY 
    P.p_name, S.s_name;