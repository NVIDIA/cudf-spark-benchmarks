SELECT 
    CONCAT(s.s_name, ' (', p.p_name, ') - ', 
           REPLACE(p.p_comment, 'fast', 'quickly')) AS supplier_part_info,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    COUNT(DISTINCT o.o_orderkey) AS distinct_orders_count
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
    s.s_acctbal > 100
    AND o.o_orderdate >= DATE '1997-01-01'
    AND o.o_orderdate < DATE '1997-12-31'
GROUP BY 
    supplier_part_info
HAVING 
    SUM(l.l_quantity) > 50
ORDER BY 
    total_quantity DESC;