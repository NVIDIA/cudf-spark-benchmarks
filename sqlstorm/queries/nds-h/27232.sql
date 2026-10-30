
SELECT 
    P.p_partkey,
    P.p_name,
    S.s_name AS supplier_name,
    C.c_name AS customer_name,
    SUM(L.l_quantity) AS total_quantity,
    MAX(L.l_extendedprice) AS max_price,
    MIN(L.l_discount) AS min_discount,
    COUNT(DISTINCT O.o_orderkey) AS order_count,
    CONCAT('Part Name: ', P.p_name, ', Supplier: ', S.s_name, ', Customer: ', C.c_name) AS details,
    UPPER(P.p_comment) AS upper_comment
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
    CHAR_LENGTH(P.p_name) > 10
    AND S.s_acctbal > 1000
    AND L.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    P.p_partkey, P.p_name, S.s_name, C.c_name, P.p_comment
HAVING 
    SUM(L.l_quantity) > 50
ORDER BY 
    total_quantity DESC, max_price DESC;
