
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
), 
CustomerRegions AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT n.n_nationkey) AS NationCount,
        SUM(s.s_acctbal) AS TotalAccountBalance
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        c.c_custkey
), 
PartSupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS TotalAvailable,
        AVG(ps.ps_supplycost) AS AvgCost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
), 
SalesData AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSales
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1997-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    o.o_orderkey,
    o.o_totalprice,
    COALESCE(c.NationCount, 0) AS CustomerNationCount,
    COALESCE(p.TotalAvailable, 0) AS PartAvailability,
    sd.TotalSales,
    CASE 
        WHEN o.o_orderstatus = 'O' THEN 'Open Order'
        WHEN o.o_orderstatus = 'F' THEN 'Filled Order'
        ELSE 'Unknown Status'
    END AS OrderStatusType
FROM 
    RankedOrders o
LEFT JOIN 
    CustomerRegions c ON o.o_orderkey = c.c_custkey
LEFT JOIN 
    PartSupplierDetails p ON o.o_orderkey = p.ps_partkey
LEFT JOIN 
    SalesData sd ON o.o_orderkey = sd.l_orderkey
WHERE 
    o.o_totalprice > (
        SELECT 
            AVG(o2.o_totalprice)
        FROM 
            orders o2
    )
ORDER BY 
    o.o_orderdate DESC, 
    o.o_orderkey DESC;
