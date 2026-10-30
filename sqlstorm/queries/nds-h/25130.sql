WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        LENGTH(p.p_name) AS name_length,
        SUBSTRING(p.p_name FROM 1 FOR 10) AS name_start_substring,
        p.p_brand,
        p.p_type,
        p.p_container,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS brand_rank
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 10 AND 20
),
SupplierSummary AS (
    SELECT 
        s.s_nationkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_acctbal
    FROM 
        supplier s
    GROUP BY 
        s.s_nationkey
),
ProductSupplier AS (
    SELECT 
        rp.p_partkey,
        rp.name_length,
        rp.name_start_substring,
        ss.supplier_count,
        ss.total_acctbal
    FROM 
        RankedParts rp
    JOIN 
        partsupp ps ON rp.p_partkey = ps.ps_partkey
    JOIN 
        SupplierSummary ss ON ps.ps_suppkey = ss.s_nationkey
    WHERE 
        rp.brand_rank <= 5
)
SELECT 
    rp.p_partkey,
    rp.name_length,
    rp.name_start_substring,
    rp.supplier_count,
    rp.total_acctbal,
    CONCAT('Part Name: ', rp.name_start_substring) AS part_description
FROM 
    ProductSupplier rp
ORDER BY 
    rp.supplier_count DESC, 
    rp.total_acctbal ASC;
