WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_mfgr,
        CONCAT(p.p_name, ' - ', p.p_brand) AS part_brand_desc,
        LENGTH(p.p_comment) AS comment_length,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS brand_rank
    FROM 
        part p
), FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        initialized_group AS avg_partsupply_cost
    FROM 
        supplier s
    JOIN (
        SELECT 
            ps.ps_suppkey,
            AVG(ps.ps_supplycost) AS initialized_group
        FROM 
            partsupp ps
        GROUP BY 
            ps.ps_suppkey
    ) avg_cost ON s.s_suppkey = avg_cost.ps_suppkey
), CombinedData AS (
    SELECT 
        rp.p_partkey,
        rp.part_brand_desc,
        fs.s_name,
        fs.avg_partsupply_cost,
        rp.comment_length,
        fs.s_acctbal
    FROM 
        RankedParts rp
    JOIN 
        FilteredSuppliers fs ON rp.p_partkey = fs.s_nationkey
    WHERE 
        rp.comment_length > 15 AND 
        fs.avg_partsupply_cost > 50
)
SELECT 
    cd.part_brand_desc,
    cd.s_name,
    cd.avg_partsupply_cost,
    cd.comment_length,
    cd.s_acctbal
FROM 
    CombinedData cd
ORDER BY 
    cd.comment_length DESC, 
    cd.avg_partsupply_cost ASC
LIMIT 50;
