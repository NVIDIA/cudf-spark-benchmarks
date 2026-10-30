WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_order
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopRevenueOrders AS (
    SELECT 
        r.o_orderkey,
        r.total_revenue,
        DENSE_RANK() OVER (ORDER BY r.total_revenue DESC) AS revenue_rank
    FROM 
        RankedOrders r
    WHERE 
        r.rank_order <= 5
)
SELECT 
    t.revenue_rank,
    COUNT(DISTINCT t.o_orderkey) AS count_of_orders,
    SUM(t.total_revenue) AS total_revenue_generated,
    AVG(t.total_revenue) AS avg_revenue_per_order
FROM 
    TopRevenueOrders t
GROUP BY 
    t.revenue_rank
ORDER BY 
    t.revenue_rank;
