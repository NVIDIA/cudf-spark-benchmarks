WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    WHERE 
        p.p_retailprice > 100.00
),
CombinedData AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        s.s_name AS supplier_name,
        ps.ps_supplycost,
        rp.p_name,
        rp.p_retailprice,
        rp.rank
    FROM 
        rankedparts rp
    JOIN 
        partsupp ps ON rp.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    region_name,
    nation_name,
    supplier_name,
    COUNT(DISTINCT p_name) AS num_parts,
    AVG(ps_supplycost) AS avg_supply_cost,
    MAX(p_retailprice) AS max_retail_price
FROM 
    CombinedData
WHERE 
    rank <= 5
GROUP BY 
    region_name, nation_name, supplier_name
ORDER BY 
    region_name, nation_name, num_parts DESC;
