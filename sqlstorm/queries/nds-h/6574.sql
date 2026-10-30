WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        c.c_nationkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, c.c_nationkey, o.o_orderdate
),
FilteredRevenue AS (
    SELECT 
        r.o_orderkey, 
        r.o_orderdate, 
        r.c_nationkey, 
        r.total_revenue, 
        n.n_name
    FROM 
        RankedOrders r
    JOIN 
        nation n ON r.c_nationkey = n.n_nationkey
    WHERE 
        r.revenue_rank <= 10
)
SELECT 
    fr.c_nationkey, 
    n.n_name, 
    COUNT(fr.o_orderkey) AS num_orders, 
    SUM(fr.total_revenue) AS total_revenue
FROM 
    FilteredRevenue fr
JOIN 
    nation n ON fr.c_nationkey = n.n_nationkey
GROUP BY 
    fr.c_nationkey, n.n_name
ORDER BY 
    total_revenue DESC;
