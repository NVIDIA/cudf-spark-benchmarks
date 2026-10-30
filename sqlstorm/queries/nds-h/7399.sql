
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice
),
TopRevenueOrders AS (
    SELECT 
        r.r_name, 
        SUM(ro.total_revenue) AS revenue_sum
    FROM 
        RankedOrders ro
    JOIN 
        customer c ON ro.o_orderkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ro.order_rank = 1
    GROUP BY 
        r.r_name
)
SELECT 
    r.r_name, 
    r.revenue_sum,
    RANK() OVER (ORDER BY r.revenue_sum DESC) AS revenue_rank
FROM 
    TopRevenueOrders r
ORDER BY 
    revenue_rank
LIMIT 10;
