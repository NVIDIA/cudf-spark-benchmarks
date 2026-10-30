WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'F') 
      AND 
        o.o_orderdate >= DATE '1996-01-01'
),
SuppliersWithHighSupplyCost AS (
    SELECT 
        ps.ps_suppkey, 
        SUM(ps.ps_supplycost) AS TotalSupplyCost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_suppkey
    HAVING 
        SUM(ps.ps_supplycost) > 10000
),
LineItemsSummary AS (
    SELECT 
        l.l_orderkey, 
        COUNT(*) AS TotalLineItems, 
        SUM(l.l_extendedprice) AS TotalExtendedPrice
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate < cast('1998-10-01' as date) - INTERVAL '30 days'
    GROUP BY 
        l.l_orderkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(DISTINCT o.o_orderkey) AS CustomerOrderCount
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 1000
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.o_orderkey, 
    r.o_orderdate, 
    r.o_totalprice, 
    r.o_orderstatus,
    cs.c_name AS CustomerName,
    cs.CustomerOrderCount,
    l.TotalLineItems,
    l.TotalExtendedPrice,
    ss.TotalSupplyCost
FROM 
    RankedOrders r
LEFT JOIN 
    CustomerOrders cs ON r.o_orderkey = cs.c_custkey
LEFT JOIN 
    LineItemsSummary l ON r.o_orderkey = l.l_orderkey
LEFT JOIN 
    SuppliersWithHighSupplyCost ss ON ss.ps_suppkey IN (
        SELECT ps_suppkey 
        FROM partsupp 
        WHERE ps_partkey IN (SELECT p_partkey FROM part WHERE p_brand = 'BrandX')
    )
WHERE 
    r.OrderRank <= 10 
    AND (ss.TotalSupplyCost IS NOT NULL OR r.o_orderstatus = 'F')
ORDER BY 
    r.o_orderdate DESC;