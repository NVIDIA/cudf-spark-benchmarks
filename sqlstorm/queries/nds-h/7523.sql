WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
), 
TopOrders AS (
    SELECT 
        r.r_name,
        COUNT(ro.o_orderkey) AS order_count,
        SUM(ro.o_totalprice) AS total_revenue
    FROM 
        RankedOrders ro
    JOIN 
        nation n ON ro.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ro.order_rank <= 10
    GROUP BY 
        r.r_name
), 
OrderSummary AS (
    SELECT 
        r.r_name,
        o.order_count,
        o.total_revenue,
        ROW_NUMBER() OVER (ORDER BY o.total_revenue DESC) AS revenue_rank
    FROM 
        TopOrders o
    JOIN 
        region r ON o.r_name = r.r_name
)
SELECT 
    r.r_name,
    r.order_count,
    r.total_revenue,
    r.revenue_rank
FROM 
    OrderSummary r
WHERE 
    r.revenue_rank <= 5
ORDER BY 
    r.total_revenue DESC;
