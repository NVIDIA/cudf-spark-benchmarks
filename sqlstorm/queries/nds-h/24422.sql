
WITH ranked_part AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS part_rank
    FROM part p
    WHERE p.p_retailprice IS NOT NULL
),
supplier_availability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
top_regions AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM supplier s
    INNER JOIN nation n ON s.s_nationkey = n.n_nationkey
    INNER JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE s.s_acctbal >= 5000
    GROUP BY n.n_regionkey, r.r_name
    ORDER BY supplier_count DESC
    LIMIT 5
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    COALESCE(pa.total_avail_qty, 0) AS total_avail_qty,
    COALESCE(pa.average_supply_cost, 0) AS average_supply_cost,
    r.r_name AS region_name,
    rp.part_rank
FROM ranked_part rp
LEFT JOIN supplier_availability pa ON rp.p_partkey = pa.ps_partkey
LEFT JOIN top_regions r ON pa.total_avail_qty > 0
WHERE rp.part_rank < 6
    AND (pa.average_supply_cost IS NULL OR pa.average_supply_cost < (SELECT AVG(ps.ps_supplycost) FROM partsupp ps))
    AND EXISTS (
        SELECT 1 
        FROM customer c 
        WHERE c.c_acctbal BETWEEN 100.00 AND 10000.00 
          AND c.c_nationkey IN (SELECT DISTINCT s.s_nationkey FROM supplier s WHERE s.s_acctbal IS NOT NULL)
          AND c.c_name LIKE '%Corp%'
    )
ORDER BY rp.p_retailprice DESC, r.r_name ASC;
