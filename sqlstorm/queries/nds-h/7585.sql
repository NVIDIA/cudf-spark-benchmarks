WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rnk
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    n.n_name AS nation,
    SUM(ro.revenue) AS total_revenue
FROM 
    RankedOrders ro
JOIN 
    customer c ON ro.o_orderkey = c.c_custkey 
JOIN 
    supplier s ON c.c_nationkey = s.s_nationkey 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
WHERE 
    ro.rnk = 1 
GROUP BY 
    n.n_name
ORDER BY 
    total_revenue DESC;
