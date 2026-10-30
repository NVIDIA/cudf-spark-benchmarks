WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_nationkey,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank_by_price
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
), 
BestCustomers AS (
    SELECT 
        nation.n_name AS Nation,
        COUNT(DISTINCT o.o_orderkey) AS OrderCount,
        SUM(o.o_totalprice) AS TotalRevenue
    FROM 
        RankedOrders o
    JOIN 
        nation ON o.c_nationkey = nation.n_nationkey
    WHERE 
        o.rank_by_price <= 10
    GROUP BY 
        nation.n_name
)
SELECT 
    bc.Nation,
    bc.OrderCount,
    bc.TotalRevenue,
    CASE WHEN bc.TotalRevenue > 500000 THEN 'High' 
         WHEN bc.TotalRevenue BETWEEN 250000 AND 500000 THEN 'Medium' 
         ELSE 'Low' END AS RevenueCategory
FROM 
    BestCustomers bc
ORDER BY 
    bc.TotalRevenue DESC;
