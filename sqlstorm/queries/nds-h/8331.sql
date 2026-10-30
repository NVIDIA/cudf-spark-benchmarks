SELECT 
    n.n_name as nation_name,
    r.r_name as region_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(o.o_totalprice) AS total_revenue,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_lineitem_value
FROM 
    customer c
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
WHERE 
    l.l_shipdate >= DATE '1997-01-01' 
    AND l.l_shipdate < DATE '1998-01-01'
    AND n.n_name IN (SELECT n.n_name FROM nation n WHERE n.n_comment LIKE '%special%')
GROUP BY 
    n.n_name, r.r_name
HAVING 
    SUM(o.o_totalprice) > 1000000
ORDER BY 
    total_revenue DESC;