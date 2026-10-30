
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        LENGTH(p.p_name) AS name_length,
        SUBSTR(p.p_name, 1, 10) AS short_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY SUBSTR(p.p_name, 1, 3) ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
),
FilteredParts AS (
    SELECT 
        rp.p_partkey,
        rp.short_name,
        rp.p_retailprice
    FROM 
        RankedParts rp
    WHERE 
        rp.price_rank <= 5
)
SELECT 
    fp.short_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    SUM(ps.ps_availqty) AS total_available_quantity
FROM 
    FilteredParts fp
JOIN 
    partsupp ps ON fp.p_partkey = ps.ps_partkey
GROUP BY 
    fp.short_name
ORDER BY 
    total_available_quantity DESC;
