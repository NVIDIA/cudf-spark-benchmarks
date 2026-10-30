
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        rg.r_name AS region_name,
        ROW_NUMBER() OVER(PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS rn,
        LENGTH(p.p_name) AS name_length,
        UPPER(p.p_comment) AS upper_comment
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region rg ON n.n_regionkey = rg.r_regionkey
    WHERE 
        p.p_size > 10 AND 
        s.s_acctbal > 100.00
), FilteredRankedParts AS (
    SELECT 
        p_partkey, 
        p_name, 
        supplier_name, 
        region_name, 
        name_length, 
        upper_comment 
    FROM 
        RankedParts 
    WHERE 
        rn = 1
)
SELECT 
    frp.p_name,
    frp.supplier_name,
    frp.region_name,
    frp.name_length,
    CONCAT(frp.upper_comment, ' (Processed)') AS final_comment
FROM 
    FilteredRankedParts frp
ORDER BY 
    frp.name_length DESC, 
    frp.supplier_name ASC;
