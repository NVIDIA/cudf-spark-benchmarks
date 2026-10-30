WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY DATE_TRUNC('month', o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopRevenueByMonth AS (
    SELECT 
        DATE_TRUNC('month', o.o_orderdate) AS order_month,
        SUM(total_revenue) AS monthly_revenue
    FROM 
        RankedOrders o
    WHERE 
        revenue_rank <= 5
    GROUP BY 
        DATE_TRUNC('month', o.o_orderdate)
)
SELECT 
    rm.order_month,
    rm.monthly_revenue,
    COUNT(DISTINCT c.c_custkey) AS unique_customers
FROM 
    TopRevenueByMonth rm
JOIN 
    orders o ON DATE_TRUNC('month', o.o_orderdate) = rm.order_month
JOIN 
    customer c ON o.o_custkey = c.c_custkey
GROUP BY 
    rm.order_month, rm.monthly_revenue
ORDER BY 
    rm.order_month;