WITH SupplierRegions AS (
    SELECT s.s_suppkey, s.s_name, r.r_name AS region_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
PartSupplierDetails AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, p.p_name, p.p_brand, p.p_type, p.p_size, p.p_retailprice
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
AggregatedData AS (
    SELECT sr.region_name, psd.p_brand, psd.p_type, COUNT(psd.ps_partkey) AS part_count,
           SUM(psd.p_retailprice) AS total_retail_price,
           COUNT(DISTINCT sr.s_suppkey) AS supplier_count
    FROM SupplierRegions sr
    JOIN PartSupplierDetails psd ON sr.s_suppkey = psd.ps_suppkey
    GROUP BY sr.region_name, psd.p_brand, psd.p_type
)
SELECT region_name, p_brand, p_type,
       part_count,
       total_retail_price,
       CASE 
           WHEN total_retail_price > 1000 THEN 'High Value'
           WHEN total_retail_price BETWEEN 500 AND 1000 THEN 'Medium Value'
           ELSE 'Low Value'
       END AS value_category
FROM AggregatedData
ORDER BY region_name, p_brand, p_type;
