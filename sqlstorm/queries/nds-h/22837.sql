
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS SupplierRank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey
), FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        CASE 
            WHEN o.o_orderstatus = 'F' THEN 'Finalized'
            ELSE 'Pending'
        END AS OrderStatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS NetRevenue
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderstatus
), SuppliersWithTotalSales AS (
    SELECT 
        r.s_suppkey,
        r.s_name,
        COALESCE(SUM(fo.NetRevenue), 0) AS TotalSales
    FROM 
        RankedSuppliers r
    LEFT JOIN 
        FilteredOrders fo ON r.s_suppkey = fo.o_custkey
    GROUP BY 
        r.s_suppkey, r.s_name
)

SELECT 
    s.s_name,
    s.TotalSales,
    CASE 
        WHEN s.TotalSales IS NULL THEN 'No Sales'
        WHEN s.TotalSales > 10000 THEN 'High Roller'
        ELSE 'Average Supplier'
    END AS SupplierCategory,
    ROW_NUMBER() OVER (ORDER BY s.TotalSales DESC) AS SalesRank
FROM 
    SuppliersWithTotalSales s
WHERE 
    (s.TotalSales IS NOT NULL AND s.TotalSales > 0) 
    OR (s.TotalSales IS NULL AND EXISTS (SELECT 1 FROM supplier su WHERE s.s_suppkey = su.s_suppkey AND su.s_name LIKE '%Inc%'))
ORDER BY 
    SalesRank;
