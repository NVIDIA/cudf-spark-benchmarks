
WITH SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS PerformanceRank
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name
),

RegionSummary AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        COUNT(DISTINCT c.c_custkey) AS TotalCustomers,
        SUM(o.o_totalprice) AS TotalSales
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_regionkey, r.r_name
)

SELECT 
    rs.r_name AS Region,
    sp.s_name AS Supplier,
    sp.TotalSupplyCost,
    sp.TotalOrders,
    rs.TotalCustomers,
    rs.TotalSales
FROM 
    SupplierPerformance sp
FULL OUTER JOIN 
    RegionSummary rs ON sp.PerformanceRank = NULLIF(rs.TotalSales, 0) / NULLIF(rs.TotalCustomers, 0)
WHERE 
    (sp.TotalOrders > 0 OR rs.TotalSales > 0)
ORDER BY 
    COALESCE(sp.TotalSupplyCost, 0) DESC, 
    COALESCE(rs.TotalSales, 0) DESC;
