SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    SUM(CASE 
        WHEN p.p_name LIKE '%rubber%' THEN ps.ps_supplycost * ps.ps_availqty 
        ELSE 0 
    END) AS total_cost_rubber_parts,
    COUNT(DISTINCT s.s_suppkey) AS unique_suppliers_rubber_parts,
    AVG(o.o_totalprice) AS avg_order_price
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
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_comment LIKE '%fragile%' 
    AND o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY 
    n.n_name, r.r_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    total_cost_rubber_parts DESC, unique_suppliers_rubber_parts DESC;