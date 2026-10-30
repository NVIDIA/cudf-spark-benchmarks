SELECT 
    n.n_name AS nation_name,
    SUM(o.o_totalprice) AS total_revenue,
    COUNT(DISTINCT c.c_custkey) AS num_customers
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
WHERE 
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    n.n_name
ORDER BY 
    total_revenue DESC;