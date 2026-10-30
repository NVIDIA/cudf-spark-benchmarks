
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopSales AS (
    SELECT 
        o_orderkey, 
        o_orderdate, 
        total_sales
    FROM 
        RankedOrders
    WHERE 
        rank = 1
)
SELECT 
    o.o_orderdate,
    COUNT(*) AS number_of_orders,
    SUM(ts.total_sales) AS total_revenue,
    AVG(ts.total_sales) AS average_order_value
FROM 
    TopSales ts
JOIN 
    orders o ON ts.o_orderkey = o.o_orderkey
GROUP BY 
    o.o_orderdate
ORDER BY 
    o.o_orderdate ASC;
