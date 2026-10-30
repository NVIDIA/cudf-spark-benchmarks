
SELECT 
    CONCAT_WS(' - ', 
        p.p_name, 
        s.s_name, 
        n.n_name, 
        r.r_name
    ) AS full_description, 
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    COUNT(DISTINCT c.c_custkey) AS unique_customers
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    orders o ON o.o_custkey = c.c_custkey
WHERE 
    p.p_comment LIKE '%fragile%' 
    AND s.s_comment LIKE '%premium%' 
GROUP BY 
    p.p_name, 
    s.s_name, 
    n.n_name, 
    r.r_name
ORDER BY 
    total_supply_cost DESC
LIMIT 10;
