SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    CASE 
        WHEN SUM(l.l_quantity) > 100 THEN 'High Demand'
        WHEN SUM(l.l_quantity) BETWEEN 50 AND 100 THEN 'Medium Demand'
        ELSE 'Low Demand' 
    END AS demand_category,
    r.r_name AS region_name,
    CONCAT('Supplier ', s.s_name, ' provided ', SUM(l.l_quantity), ' of ', p.p_name) AS detailed_comment
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
WHERE 
    l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, c.c_name, r.r_name
ORDER BY 
    revenue DESC, part_name ASC;