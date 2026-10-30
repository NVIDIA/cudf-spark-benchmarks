SELECT 
    n.n_name AS nation_name,
    SUM(CASE 
        WHEN c.c_mktsegment LIKE 'AUTOMOBILE%' THEN l.l_extendedprice * (1 - l.l_discount) 
        ELSE 0 
    END) AS total_revenue
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    n.n_name
ORDER BY 
    total_revenue DESC
LIMIT 10;