WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS Rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
BestSuppliers AS (
    SELECT 
        r.r_name AS Region,
        n.n_name AS Nation,
        rs.s_suppkey,
        rs.s_name,
        rs.TotalCost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_suppkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.Rank = 1
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS OrderCount,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    COUNT(DISTINCT co.c_custkey) AS CustomersWithOrders,
    COUNT(DISTINCT bs.s_suppkey) AS BestSuppliersCount,
    SUM(co.TotalSpent) AS TotalSpentByCustomers,
    AVG(co.OrderCount) AS AverageOrdersPerCustomer,
    (SELECT 
         AVG(ps.ps_availqty)
     FROM 
         partsupp ps) AS AveragePartsAvailable,
    MAX(bs.TotalCost) AS MaxSupplierCost
FROM 
    CustomerOrders co
FULL OUTER JOIN 
    BestSuppliers bs ON 1 = 1
WHERE 
    co.TotalSpent IS NOT NULL OR bs.TotalCost IS NOT NULL
AND 
    (bs.TotalCost BETWEEN 50000 AND 100000 OR co.TotalSpent > 10000)
ORDER BY 
    CustomersWithOrders DESC, BestSuppliersCount DESC;
