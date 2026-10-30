WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           CONCAT(s.s_name, ' - ', s.s_address, ' (', s.s_phone, ')') AS SupplierInfo
    FROM supplier s
), 
NationDetails AS (
    SELECT n.n_nationkey, n.n_name AS NationName 
    FROM nation n
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, 
           CONCAT(p.p_name, ' [', p.p_brand, '] - ', p.p_comment) AS PartInfo
    FROM part p
),
AggregatedData AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, 
           SUM(ps.ps_availqty) AS TotalAvailable, 
           MIN(ps.ps_supplycost) AS MinSupplyCost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
)
SELECT 
    sd.SupplierInfo, 
    nd.NationName, 
    pd.PartInfo, 
    ad.TotalAvailable, 
    ad.MinSupplyCost
FROM AggregatedData ad
JOIN SupplierDetails sd ON ad.ps_suppkey = sd.s_suppkey
JOIN PartDetails pd ON ad.ps_partkey = pd.p_partkey
JOIN NationDetails nd ON sd.s_nationkey = nd.n_nationkey
WHERE ad.TotalAvailable > 100
ORDER BY sd.SupplierInfo, ad.MinSupplyCost DESC;
