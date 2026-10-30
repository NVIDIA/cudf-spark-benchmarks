WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS Revenue,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS OrderRank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),

TopRevenueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.Revenue
    FROM 
        RankedOrders ro
    WHERE 
        ro.OrderRank <= 10
)

SELECT 
    tr.o_orderdate,
    COUNT(tr.o_orderkey) AS TotalOrders,
    SUM(tr.Revenue) AS TotalRevenue,
    AVG(tr.Revenue) AS AverageRevenue
FROM 
    TopRevenueOrders tr
GROUP BY 
    tr.o_orderdate
ORDER BY 
    tr.o_orderdate;
