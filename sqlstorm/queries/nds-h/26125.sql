WITH EnhancedSupplier AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           CONCAT(s.s_name, ' ', LEFT(s.s_address, 20), ' ', s.s_phone) AS SupplierDetails,
           (SELECT COUNT(*) FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey) AS PartSuppCount
    FROM supplier s
),
NationAlias AS (
    SELECT n.n_nationkey, n.n_name, r.r_name AS RegionName,
           CONCAT(n.n_name, ' ', r.r_name) AS NationRegion
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
ProcessedData AS (
    SELECT es.SupplierDetails, na.NationRegion, SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
           COUNT(DISTINCT c.c_custkey) AS CustomerCount
    FROM EnhancedSupplier es
    JOIN lineitem l ON l.l_suppkey = es.s_suppkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN NationAlias na ON es.s_nationkey = na.n_nationkey
    WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY es.SupplierDetails, na.NationRegion
)
SELECT SupplierDetails, NationRegion, TotalRevenue, CustomerCount
FROM ProcessedData
ORDER BY TotalRevenue DESC, CustomerCount DESC;