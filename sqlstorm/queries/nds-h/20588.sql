WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N' AND 
        l.l_shipmode IN ('SHIP', 'AIR') 
    GROUP BY 
        l.l_orderkey
),
SupplierStats AS (
    SELECT 
        ps.ps_suppkey,
        AVG(ps.ps_supplycost) AS AvgSupplyCost,
        COUNT(DISTINCT ps.ps_partkey) AS PartCount
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(o.o_totalprice), 0) AS TotalPurchases,
        COUNT(DISTINCT o.o_orderkey) AS OrderCount
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    COALESCE(l.TotalRevenue, 0) AS TotalRevenue,
    s.AvgSupplyCost,
    c.TotalPurchases,
    c.OrderCount
FROM 
    RankedOrders o
LEFT JOIN 
    FilteredLineItems l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    SupplierStats s ON s.ps_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_brand = 'BrandX') LIMIT 1)
LEFT JOIN 
    CustomerOrderSummary c ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = o.o_orderkey LIMIT 1)
WHERE 
    EXISTS (SELECT 1 FROM lineitem li WHERE li.l_orderkey = o.o_orderkey AND li.l_quantity > 1)
ORDER BY 
    o.o_orderdate DESC, 
    TotalRevenue DESC
LIMIT 10;
