
SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(CASE 
        WHEN p.p_size <= 10 THEN ps.ps_supplycost 
        ELSE NULL 
    END) AS avg_cost_small_parts,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_supplied,
    CONCAT('Total Price: $', CAST(SUM(l.l_extendedprice * (1 - l.l_discount)) AS STRING)) AS total_sales
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
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
GROUP BY 
    s.s_name, p.p_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    SUM(l.l_extendedprice * (1 - l.l_discount)) DESC;
