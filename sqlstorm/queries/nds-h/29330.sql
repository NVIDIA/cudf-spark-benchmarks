WITH PartSupplierInfo AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        s.s_name AS supplier_name, 
        s.s_acctbal, 
        ps.ps_availqty, 
        ps.ps_supplycost,
        CONCAT(p.p_name, ' | ', s.s_name, ' | ', s.s_acctbal) AS combined_info
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        LENGTH(p.p_name) > 10 AND 
        s.s_acctbal > 1000
),
AggregatedData AS (
    SELECT 
        LEFT(combined_info, 50) AS short_info,
        COUNT(*) AS supplier_count,
        SUM(ps_supplycost) AS total_supply_cost
    FROM 
        PartSupplierInfo
    GROUP BY 
        short_info
)
SELECT 
    short_info, 
    supplier_count, 
    total_supply_cost
FROM 
    AggregatedData
ORDER BY 
    supplier_count DESC, total_supply_cost DESC
LIMIT 10;
