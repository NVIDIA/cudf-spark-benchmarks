
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
),
SupplierSales AS (
    SELECT 
        ps.ps_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSales
    FROM 
        lineitem l
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    GROUP BY 
        ps.ps_suppkey
),
CustomerSegment AS (
    SELECT 
        c.c_mktsegment,
        COUNT(DISTINCT o.o_orderkey) AS OrderCount,
        SUM(o.o_totalprice) AS TotalRevenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        c.c_mktsegment
)
SELECT 
    r.r_name,
    SUM(ss.TotalSales) AS RegionTotalSales,
    SUM(cs.TotalRevenue) AS SegmentTotalRevenue,
    COUNT(DISTINCT ro.o_orderkey) AS RecentOrderCount
FROM 
    Region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierSales ss ON s.s_suppkey = ss.ps_suppkey
LEFT JOIN 
    CustomerSegment cs ON r.r_name = cs.c_mktsegment
LEFT JOIN 
    RankedOrders ro ON s.s_suppkey = ro.o_orderkey
GROUP BY 
    r.r_name
ORDER BY 
    RegionTotalSales DESC, SegmentTotalRevenue DESC;
