WITH SupplierOrders AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSales,
        COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
        AVG(l.l_quantity) AS AvgQuantity,
        COUNT(DISTINCT l.l_orderkey) AS DistinctOrderCount
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name
), RegionPerformance AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        SUM(so.TotalSales) AS TotalSalesByRegion,
        AVG(so.AvgQuantity) AS AvgQuantityByRegion,
        SUM(so.TotalOrders) AS TotalOrdersByRegion
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        SupplierOrders so ON s.s_suppkey = so.s_suppkey
    GROUP BY 
        n.n_regionkey, r.r_name
)
SELECT 
    r.r_name,
    rp.TotalSalesByRegion,
    rp.AvgQuantityByRegion,
    rp.TotalOrdersByRegion
FROM 
    RegionPerformance rp
JOIN 
    region r ON rp.n_regionkey = r.r_regionkey
ORDER BY 
    rp.TotalSalesByRegion DESC,
    r.r_name;