WITH StringBenchmark AS (
    SELECT 
        p.p_mfgr, 
        CONCAT(p.p_name, ' - ', p.p_type) AS part_details, 
        LENGTH(p.p_comment) AS comment_length,
        COUNT(ps.ps_partkey) AS supplier_count,
        MAX(ps.ps_supplycost) AS max_supply_cost,
        AVG(ps.ps_availqty) AS avg_availability
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        LOWER(p.p_name) LIKE '%steel%' 
        AND p.p_size < 30 
    GROUP BY 
        p.p_mfgr, p.p_name, p.p_type, p.p_comment
),
RankedManufacturers AS (
    SELECT 
        p_mfgr, 
        part_details, 
        comment_length,
        supplier_count,
        max_supply_cost,
        avg_availability,
        RANK() OVER (ORDER BY supplier_count DESC, max_supply_cost DESC) AS ranking
    FROM 
        StringBenchmark
)
SELECT 
    r.r_name AS region_name, 
    nm.n_name AS nation_name, 
    rm.part_details, 
    rm.comment_length, 
    rm.supplier_count, 
    rm.max_supply_cost, 
    rm.avg_availability,
    rm.ranking
FROM 
    RankedManufacturers rm
JOIN 
    supplier s ON s.s_name = rm.p_mfgr
JOIN 
    nation nm ON s.s_nationkey = nm.n_nationkey
JOIN 
    region r ON nm.n_regionkey = r.r_regionkey
WHERE 
    rm.ranking <= 10
ORDER BY 
    rm.ranking, r.r_name;
