WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
TopNations AS (
    SELECT 
        n.n_name,
        SUM(orders_count) AS total_orders,
        RANK() OVER (ORDER BY SUM(orders_count) DESC) AS nation_rank
    FROM 
        (SELECT 
            c.c_nationkey,
            COUNT(o.o_orderkey) AS orders_count
         FROM 
            customer c
         JOIN 
            orders o ON c.c_custkey = o.o_custkey
         GROUP BY 
            c.c_nationkey) AS nation_orders
    JOIN 
        nation n ON nation_orders.c_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
),
FinalResults AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT so.o_orderkey) AS total_unique_orders,
        SUM(so.total_revenue) AS total_revenue_generated
    FROM 
        RankedOrders so
    JOIN 
        customer c ON c.c_custkey = so.o_orderkey  
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        so.order_rank <= 5
    GROUP BY 
        r.r_name
)
SELECT 
    r.r_name, 
    r.total_unique_orders, 
    r.total_revenue_generated 
FROM 
    FinalResults r
JOIN 
    TopNations t ON r.r_name = t.n_name
WHERE 
    t.nation_rank <= 10
ORDER BY 
    r.total_revenue_generated DESC;