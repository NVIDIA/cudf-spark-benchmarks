SELECT 
    n.n_name AS nation_name, 
    r.r_name AS region_name, 
    COUNT(DISTINCT c.c_custkey) AS customer_count, 
    SUM(o.o_totalprice) AS total_revenue
FROM 
    customer c
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
GROUP BY 
    n.n_name, r.r_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
