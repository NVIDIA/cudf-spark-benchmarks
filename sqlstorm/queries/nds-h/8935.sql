WITH OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        r.r_name AS region_name
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, r.r_name
),
RankedOrders AS (
    SELECT 
        os.*,
        RANK() OVER (PARTITION BY os.region_name ORDER BY os.total_revenue DESC) AS revenue_rank
    FROM 
        OrderSummary os
)
SELECT 
    ro.region_name,
    COUNT(ro.o_orderkey) AS order_count,
    AVG(ro.total_revenue) AS average_revenue,
    SUM(CASE WHEN ro.revenue_rank <= 10 THEN 1 ELSE 0 END) AS top_orders_count
FROM 
    RankedOrders ro
GROUP BY 
    ro.region_name
ORDER BY 
    average_revenue DESC;
