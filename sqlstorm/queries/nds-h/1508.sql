WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        COUNT(DISTINCT ps.ps_partkey) AS TotalPartsSupplied,
        AVG(s.s_acctbal) AS AvgAccountBalance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS Revenue,
        SUM(l.l_quantity) AS TotalQuantity,
        COUNT(DISTINCT l.l_partkey) AS UniqueParts
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    s.TotalSupplyCost,
    s.TotalPartsSupplied,
    d.Revenue,
    d.TotalQuantity,
    d.UniqueParts,
    CASE 
        WHEN d.Revenue IS NULL THEN 'No Revenue'
        WHEN d.Revenue > 1000 THEN 'High Revenue'
        ELSE 'Low Revenue' 
    END AS RevenueCategory
FROM 
    RankedOrders r
LEFT JOIN 
    OrderDetails d ON r.o_orderkey = d.l_orderkey
LEFT JOIN 
    SupplierSummary s ON s.TotalSupplyCost = (SELECT MAX(TotalSupplyCost) FROM SupplierSummary)
WHERE 
    r.OrderRank <= 10
ORDER BY 
    r.o_totalprice DESC, r.o_orderdate ASC
LIMIT 20;