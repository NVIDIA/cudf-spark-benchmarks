
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rnk,
        n.n_nationkey
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, n.n_nationkey
),
TopNationRevenue AS (
    SELECT 
        n.n_name,
        SUM(r.revenue) AS total_revenue
    FROM 
        RankedOrders r
    JOIN 
        nation n ON r.n_nationkey = n.n_nationkey
    WHERE 
        r.rnk <= 3
    GROUP BY 
        n.n_name
)
SELECT 
    r.n_name AS nation,
    COALESCE(t.total_revenue, 0) AS revenue
FROM 
    nation r
LEFT JOIN 
    TopNationRevenue t ON r.n_name = t.n_name
ORDER BY 
    revenue DESC;
