WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        DENSE_RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS CostRank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    LEFT OUTER JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    n.n_name,
    r.r_name,
    COALESCE(SuppliersByNation.TotalCost, 0) AS TotalCostByNation,
    COALESCE(CustomersByNation.TotalSpent, 0) AS TotalSpentByNation,
    CASE 
        WHEN COALESCE(SuppliersByNation.TotalCost, 0) > COALESCE(CustomersByNation.TotalSpent, 0) 
        THEN 'Suppliers Lead'
        ELSE 'Customers Lead'
    END AS LeadershipStatus
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN (
    SELECT 
        n.n_nationkey, 
        SUM(rs.TotalCost) AS TotalCost 
    FROM 
        RankedSuppliers rs
    JOIN 
        supplier s ON rs.s_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_nationkey
) SuppliersByNation ON n.n_nationkey = SuppliersByNation.n_nationkey
LEFT JOIN (
    SELECT 
        c.c_nationkey, 
        SUM(co.TotalSpent) AS TotalSpent 
    FROM 
        CustomerOrders co
    JOIN 
        customer c ON co.c_custkey = c.c_custkey
    GROUP BY 
        c.c_nationkey
) CustomersByNation ON n.n_nationkey = CustomersByNation.c_nationkey
WHERE 
    r.r_name LIKE '%%' AND 
    (SuppliersByNation.TotalCost IS NULL OR CustomersByNation.TotalSpent IS NULL OR 
    (SuppliersByNation.TotalCost / NULLIF(CustomersByNation.TotalSpent, 0)) < 10)
ORDER BY 
    n.n_name, 
    r.r_name;
