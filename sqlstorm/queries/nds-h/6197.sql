WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
), TopOrders AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        COUNT(ro.o_orderkey) AS total_orders,
        SUM(ro.o_totalprice) AS total_revenue
    FROM 
        RankedOrders ro
    JOIN 
        customer c ON ro.o_orderkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ro.order_rank <= 5
    GROUP BY 
        r.r_name, n.n_name
)
SELECT 
    region_name,
    nation_name,
    total_orders,
    total_revenue,
    ROUND(total_revenue / total_orders, 2) AS avg_order_value
FROM 
    TopOrders
ORDER BY 
    total_revenue DESC, total_orders DESC;