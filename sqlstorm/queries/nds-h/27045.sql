SELECT 
    CONCAT('Supplier: ', s.s_name, ', located in nation: ', n.n_name) AS supplier_info,
    SUM(CASE 
        WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) 
        ELSE 0 
    END) AS total_revenue_from_returns,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(p.p_retailprice) AS avg_part_price,
    COUNT(DISTINCT p.p_partkey) AS distinct_parts_count
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    n.n_name LIKE '%United%'
    AND l.l_shipdate >= '1997-01-01' 
    AND l.l_shipdate < '1998-01-01'
GROUP BY 
    supplier_info
ORDER BY 
    total_revenue_from_returns DESC, total_orders DESC
LIMIT 10;