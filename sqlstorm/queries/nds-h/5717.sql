SELECT 
    n.n_name AS nation_name,
    SUM(CASE 
            WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) 
            ELSE 0 
        END) AS total_revenue_returned,
    SUM(CASE 
            WHEN l.l_returnflag = 'A' THEN l.l_extendedprice * (1 - l.l_discount) 
            ELSE 0 
        END) AS total_revenue_accepted,
    AVG(CASE 
            WHEN l.l_returnflag = 'R' THEN l.l_quantity 
            ELSE NULL 
        END) AS avg_quantity_returned,
    AVG(CASE 
            WHEN l.l_returnflag = 'A' THEN l.l_quantity 
            ELSE NULL 
        END) AS avg_quantity_accepted
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    n.n_name
ORDER BY 
    total_revenue_returned DESC, total_revenue_accepted DESC
LIMIT 10;