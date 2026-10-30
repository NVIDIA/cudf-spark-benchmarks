WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopRevenueOrders AS (
    SELECT 
        ro.o_orderkey, 
        ro.o_orderdate, 
        ro.total_revenue,
        c.c_name,
        c.c_nationkey
    FROM 
        RankedOrders ro
    JOIN 
        customer c ON ro.o_orderkey = c.c_custkey
    WHERE 
        ro.revenue_rank <= 10
)
SELECT 
    tro.o_orderkey,
    tro.o_orderdate,
    tro.total_revenue,
    c.c_name AS customer_name,
    n.n_name AS nation_name,
    r.r_name AS region_name
FROM 
    TopRevenueOrders tro
JOIN 
    customer c ON tro.c_nationkey = c.c_nationkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
ORDER BY 
    tro.total_revenue DESC;