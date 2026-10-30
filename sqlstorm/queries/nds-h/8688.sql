WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_nationkey,
        DENSE_RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
OrderDetails AS (
    SELECT 
        r.r_name AS region,
        n.n_name AS nation,
        COUNT(ro.o_orderkey) AS order_count,
        SUM(ro.o_totalprice) AS total_revenue
    FROM 
        RankedOrders ro
    JOIN 
        nation n ON n.n_nationkey = ro.c_nationkey
    JOIN 
        region r ON r.r_regionkey = n.n_regionkey
    WHERE 
        ro.order_rank <= 10 
    GROUP BY 
        r.r_name, n.n_name
)
SELECT 
    region,
    nation,
    order_count,
    total_revenue,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM 
    OrderDetails
WHERE 
    order_count > 5
ORDER BY 
    revenue_rank;
