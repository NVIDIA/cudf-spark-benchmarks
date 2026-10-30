WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyValue,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS SupplierRank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > (
            SELECT AVG(o_totalprice) 
            FROM orders 
            WHERE o_orderstatus = 'O'
        )
),
RegionSales AS (
    SELECT 
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSales
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        r.r_name
)
SELECT 
    hs.c_custkey,
    hs.c_name,
    rs.r_name,
    rs.TotalSales,
    rs.TotalSales / NULLIF(AVG(rs.TotalSales) OVER (), 0) AS SalesRatio,
    rs.TotalSales * 0.1 AS DiscountedSalesValue,
    rs.TotalSales * 0.1 / COUNT(rs.r_name) OVER () AS AverageDiscountedSalesValue
FROM 
    HighValueCustomers hs
JOIN 
    RegionSales rs ON hs.TotalSpent > rs.TotalSales
ORDER BY 
    hs.TotalSpent DESC, SalesRatio DESC;
