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
TopMonths AS (
    SELECT 
        DATE_TRUNC('month', o_orderdate) AS sales_month,
        SUM(total_revenue) AS monthly_revenue
    FROM 
        RankedOrders
    WHERE 
        revenue_rank <= 5
    GROUP BY 
        sales_month
)
SELECT 
    t.sales_month,
    AVG(t.monthly_revenue) AS average_top_revenue
FROM 
    TopMonths t
GROUP BY 
    t.sales_month
ORDER BY 
    t.sales_month ASC;