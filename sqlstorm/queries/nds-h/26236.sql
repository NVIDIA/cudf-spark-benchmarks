SELECT 
    P.p_partkey, 
    P.p_name, 
    S.s_name AS supplier_name, 
    C.c_name AS customer_name, 
    O.o_orderkey, 
    O.o_orderdate, 
    L.l_quantity,
    L.l_extendedprice,
    SUBSTRING(P.p_name FROM 1 FOR 10) AS short_name,
    CONCAT('Part: ', P.p_name, ' | Supplier: ', S.s_name, ' | Customer: ', C.c_name) AS detailed_info
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
WHERE 
    P.p_size > 10 
    AND S.s_acctbal > 1000.00 
    AND O.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
ORDER BY 
    O.o_orderdate DESC, 
    L.l_quantity DESC;