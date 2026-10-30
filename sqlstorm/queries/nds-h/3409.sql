WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS SupplierRank
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
        COUNT(o.o_orderkey) AS OrderCount,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
NationSummary AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        COALESCE(SUM(cs.TotalSpent), 0) AS TotalCustomerSpent,
        COALESCE(MAX(rs.TotalSupplyCost), 0) AS MaxSupplierCost
    FROM 
        nation n
    LEFT JOIN 
        CustomerOrders cs ON n.n_nationkey = cs.c_custkey
    LEFT JOIN 
        RankedSuppliers rs ON n.n_nationkey = rs.s_suppkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    ns.n_name,
    ns.TotalCustomerSpent,
    ns.MaxSupplierCost,
    CASE 
        WHEN ns.TotalCustomerSpent > ns.MaxSupplierCost THEN 'Spending Above Average Supplier Cost'
        ELSE 'Spending Below Average Supplier Cost'
    END AS SpendingStatus
FROM 
    NationSummary ns
WHERE 
    ns.TotalCustomerSpent IS NOT NULL AND ns.MaxSupplierCost IS NOT NULL
ORDER BY 
    ns.TotalCustomerSpent DESC;
