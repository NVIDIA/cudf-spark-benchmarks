WITH SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        COUNT(DISTINCT ps.ps_partkey) AS PartCount
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
HighPerformanceSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sp.TotalCost,
        sp.PartCount,
        RANK() OVER (ORDER BY sp.TotalCost DESC) AS RankByCost
    FROM SupplierPerformance sp
    JOIN supplier s ON sp.s_suppkey = s.s_suppkey
    WHERE sp.TotalCost > (
        SELECT AVG(TotalCost) 
        FROM SupplierPerformance
    )
),
OrderMetrics AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS NetRevenue,
        COUNT(DISTINCT l.l_linenumber) AS LineItemCount,
        o.o_orderstatus
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_orderstatus
)
SELECT 
    h.s_name AS SupplierName,
    AVG(o.NetRevenue) AS AvgOrderRevenue,
    MAX(o.LineItemCount) AS MaxLineItemInOrder,
    SUM(o.NetRevenue) AS TotalRevenueThisYear,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) > 0 THEN 'Participated'
        ELSE 'Not Participated'
    END AS OrderParticipationStatus
FROM HighPerformanceSuppliers h
LEFT JOIN OrderMetrics o ON h.s_suppkey = o.o_orderkey
GROUP BY h.s_name
HAVING SUM(o.NetRevenue) IS NOT NULL
ORDER BY AvgOrderRevenue DESC NULLS LAST;