
WITH RankedParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        COUNT(*) OVER (PARTITION BY p.p_brand ORDER BY p.p_name) AS brand_rank,
        SUM(ps.ps_supplycost * ps.ps_availqty) OVER (PARTITION BY p.p_partkey) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice > 50.00
)
SELECT
    rp.p_partkey,
    rp.p_name,
    rp.p_brand,
    rp.p_type,
    rp.brand_rank,
    rp.total_supply_cost,
    CASE
        WHEN rp.brand_rank < 10 THEN 'Top Brand'
        WHEN rp.brand_rank BETWEEN 10 AND 30 THEN 'Mid Brand'
        ELSE 'Low Brand'
    END AS brand_category,
    CONCAT('Supply cost for ', rp.p_name, ' is ', CAST(rp.total_supply_cost AS VARCHAR(20))) AS supply_cost_message
FROM RankedParts rp
WHERE rp.total_supply_cost > 1000.00
ORDER BY rp.total_supply_cost DESC, rp.brand_rank ASC;
