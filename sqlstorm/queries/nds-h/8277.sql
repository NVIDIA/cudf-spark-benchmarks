WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1996-01-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopSales AS (
    SELECT 
        ro.o_orderkey, 
        ro.o_orderdate, 
        ro.total_revenue
    FROM 
        RankedOrders ro
    WHERE 
        ro.revenue_rank <= 10
)
SELECT 
    c.c_name,
    c.c_acctbal,
    ts.o_orderkey,
    ts.total_revenue
FROM 
    TopSales ts
JOIN 
    orders o ON ts.o_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    c.c_acctbal > 1000
ORDER BY 
    ts.total_revenue DESC;