SELECT 
    CONCAT('Supplier: ', s_name, ' | Part: ', p_name, ' | Region: ', r_name) AS supplier_part_info,
    COUNT(DISTINCT o_orderkey) AS total_orders,
    AVG(l_extendedprice * (1 - l_discount)) AS average_price_after_discount,
    SUM(CASE WHEN l_returnflag = 'R' THEN l_quantity ELSE 0 END) AS total_returned_quantity
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
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name LIKE '%East%' AND
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    supplier_part_info
ORDER BY 
    total_orders DESC, average_price_after_discount ASC
LIMIT 10;