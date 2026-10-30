SELECT 
    CONCAT_WS(' ', c.c_name, c.c_address) AS customer_info,
    p.p_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(CASE 
            WHEN l.l_discount > 0 THEN l.l_extendedprice * (1 - l.l_discount)
            ELSE l.l_extendedprice 
        END) AS average_price_after_discount,
    COUNT(DISTINCT o.o_orderkey) AS distinct_orders,
    COUNT(DISTINCT s.s_suppkey) AS distinct_suppliers
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
WHERE 
    p.p_retailprice > 100.00 
    AND c.c_acctbal < 5000.00 
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    c.c_name, c.c_address, p.p_name
ORDER BY 
    total_quantity DESC, average_price_after_discount ASC;