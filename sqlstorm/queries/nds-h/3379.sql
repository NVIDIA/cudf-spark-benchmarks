
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        RANK() OVER (PARTITION BY p.p_type ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS Rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_type
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS OrderCount,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierTopPart AS (
    SELECT 
        ps.ps_partkey,
        MAX(ps.ps_availqty) AS MaxAvailQty
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
FinalReport AS (
    SELECT 
        cs.c_custkey,
        cs.c_name,
        rs.s_name AS TopSupplier,
        rs.TotalSupplyCost,
        cs.OrderCount,
        cs.TotalSpent,
        CASE 
            WHEN cs.TotalSpent > 10000 THEN 'High Roller'
            WHEN cs.TotalSpent IS NULL THEN 'No Orders'
            ELSE 'Regular Customer'
        END AS CustomerType
    FROM 
        CustomerOrderStats cs
    LEFT JOIN 
        RankedSuppliers rs ON cs.c_custkey = rs.s_suppkey
    LEFT JOIN 
        SupplierTopPart sp ON sp.ps_partkey = rs.s_suppkey
)
SELECT 
    fr.c_custkey,
    fr.c_name,
    fr.TopSupplier,
    fr.TotalSupplyCost,
    fr.OrderCount,
    fr.TotalSpent,
    fr.CustomerType
FROM 
    FinalReport fr
WHERE 
    fr.OrderCount > 2
    OR fr.TotalSpent IS NOT NULL
ORDER BY 
    fr.TotalSpent DESC, fr.c_name ASC;
