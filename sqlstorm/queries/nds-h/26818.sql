WITH supplier_part_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_name,
        p.p_brand,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
top_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_supply_cost DESC
    LIMIT 5
)
SELECT 
    tsi.s_suppkey,
    tsi.s_name,
    spi.p_name,
    spi.p_brand,
    spi.ps_availqty,
    spi.ps_supplycost
FROM supplier_part_info spi
JOIN top_suppliers tsi ON spi.s_suppkey = tsi.s_suppkey
WHERE spi.rn = 1
ORDER BY tsi.total_supply_cost DESC, spi.ps_supplycost ASC;
