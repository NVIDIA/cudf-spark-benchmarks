SELECT 
    n.n_name AS nation_name,
    sum(l.l_extendedprice * (1 - l.l_discount)) AS total_yearly_revenue
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
WHERE 
    l.l_shipdate >= DATE '1996-01-01' AND l.l_shipdate < DATE '1997-01-01'
GROUP BY 
    n.n_name
ORDER BY 
    total_yearly_revenue DESC
LIMIT 10;