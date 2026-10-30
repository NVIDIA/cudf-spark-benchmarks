WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS customer_count,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
TopStatusOrders AS (
    SELECT 
        o_orderstatus, 
        total_revenue, 
        customer_count 
    FROM 
        RankedOrders 
    WHERE 
        revenue_rank <= 5
),
OrderDetails AS (
    SELECT 
        ts.o_orderstatus,
        COUNT(ts.total_revenue) AS orders_count,
        AVG(ts.total_revenue) AS avg_revenue,
        SUM(ts.customer_count) AS total_customers
    FROM 
        TopStatusOrders ts
    GROUP BY 
        ts.o_orderstatus
)
SELECT 
    ods.o_orderstatus,
    ods.orders_count,
    ods.avg_revenue,
    ods.total_customers,
    ROUND(ods.avg_revenue / ods.orders_count, 2) AS avg_revenue_per_order
FROM 
    OrderDetails ods
ORDER BY 
    ods.avg_revenue DESC;