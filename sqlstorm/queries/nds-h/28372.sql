
WITH RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_container, 
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_price,
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY LENGTH(p.p_name) DESC) AS rank_length
    FROM part p
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_container,
           CONCAT(p.p_name, ' - ', p.p_brand) AS full_description
    FROM RankedParts p
    WHERE rank_price <= 5 AND rank_length <= 5
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, p.full_description,
           CONCAT(SUBSTRING(s.s_address, 1, 20), '...') AS short_address
    FROM supplier s
    JOIN FilteredParts p ON s.s_suppkey = p.p_partkey
)
SELECT sd.s_suppkey, sd.s_name, sd.short_address, sd.full_description,
       COUNT(ol.o_orderkey) AS order_count
FROM SupplierDetails sd
LEFT JOIN orders ol ON ol.o_custkey = sd.s_suppkey
GROUP BY sd.s_suppkey, sd.s_name, sd.short_address, sd.full_description
HAVING COUNT(ol.o_orderkey) > 2
ORDER BY order_count DESC, sd.s_name ASC;
