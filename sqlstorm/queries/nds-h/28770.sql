
WITH SupplierPartDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        p.p_name, 
        p.p_brand, 
        p.p_type, 
        ps.ps_availqty, 
        ps.ps_supplycost, 
        CONCAT(s.s_name, ' supplies ', p.p_name, ' of type ', p.p_type) AS description
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
AggregatedDetails AS (
    SELECT 
        spd.s_name, 
        COUNT(spd.p_name) AS part_count, 
        SUM(spd.ps_availqty) AS total_available_qty, 
        AVG(spd.ps_supplycost) AS avg_supply_cost,
        SUBSTRING(spd.description, 1, 40) AS short_description
    FROM SupplierPartDetails spd
    GROUP BY spd.s_name, spd.description
)
SELECT 
    ad.s_name, 
    ad.part_count, 
    ad.total_available_qty, 
    ad.avg_supply_cost, 
    CONCAT(ad.short_description, '...') AS trimmed_description
FROM AggregatedDetails ad
ORDER BY ad.part_count DESC, ad.total_available_qty DESC
LIMIT 10;
