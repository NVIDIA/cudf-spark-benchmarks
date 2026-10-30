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
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        c.c_custkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSales,
        COUNT(l.l_orderkey) AS LineItemCount
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY 
        o.o_orderkey, c.c_custkey
),
FilteredOrders AS (
    SELECT 
        od.o_orderkey, 
        od.c_custkey, 
        od.TotalSales,
        ROW_NUMBER() OVER (ORDER BY od.TotalSales DESC) AS SalesRank
    FROM 
        OrderDetails od
    WHERE 
        od.LineItemCount > 5
)
SELECT 
    r.r_name, 
    COUNT(DISTINCT fo.c_custkey) AS UniqueCustomers,
    SUM(fo.TotalSales) AS TotalSalesAmount,
    MAX(rs.TotalSupplyCost) AS HighestSupplyCost
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey
LEFT JOIN 
    FilteredOrders fo ON s.s_suppkey = fo.c_custkey
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT fo.c_custkey) > 0 OR MAX(rs.TotalSupplyCost) IS NOT NULL;