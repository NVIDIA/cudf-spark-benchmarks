SELECT 
    n.n_name AS nation_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(c.c_acctbal) AS avg_customer_balance
FROM 
    customer AS c
JOIN 
    orders AS o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem AS l ON o.o_orderkey = l.l_orderkey
JOIN 
    supplier AS s ON l.l_suppkey = s.s_suppkey
JOIN 
    partsupp AS ps ON l.l_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
JOIN 
    nation AS n ON c.c_nationkey = n.n_nationkey
WHERE 
    o.o_orderdate >= DATE '1995-01-01' 
    AND o.o_orderdate < DATE '1996-01-01'
    AND l.l_shipdate >= DATE '1995-01-01'
    AND l.l_shipdate < DATE '1996-01-01'
GROUP BY 
    n.n_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > (SELECT AVG(total_revenue) FROM (
        SELECT 
            SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
        FROM 
            orders AS o
        JOIN 
            lineitem AS l ON o.o_orderkey = l.l_orderkey
        WHERE 
            o.o_orderdate >= DATE '1995-01-01' 
            AND o.o_orderdate < DATE '1996-01-01'
        GROUP BY 
            o.o_orderkey
    ) AS avg_revenue)
ORDER BY 
    total_revenue DESC;