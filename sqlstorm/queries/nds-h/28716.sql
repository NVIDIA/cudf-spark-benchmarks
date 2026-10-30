SELECT 
    CONCAT(
        'Supplier Name: ', s_name, 
        ', Part Name: ', p_name, 
        ', Order Key: ', o_orderkey, 
        ', Quantity: ', l_quantity, 
        ', Order Date: ', o_orderdate
    ) AS order_details
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    s.s_acctbal > (
        SELECT AVG(s2.s_acctbal) 
        FROM supplier s2
    )
AND 
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
ORDER BY 
    o.o_orderdate DESC
LIMIT 100;