
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
        COUNT(ps.ps_suppkey) AS supplier_count,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, 
        p.p_size, p.p_container, p.p_retailprice, p.p_comment
),
TopParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        r.r_name AS region_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        RankedParts p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        p.rank <= 5
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, 
        p.p_type, p.p_retailprice, r.r_name, n.n_name
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    p.p_brand,
    p.p_type,
    p.p_retailprice,
    p.region_name,
    p.nation_name,
    CONCAT('Total Supply Cost: $', CAST(ROUND(p.total_supplycost, 2) AS STRING)) AS cost_details
FROM 
    TopParts p
ORDER BY 
    p.p_retailprice DESC, p.total_supplycost ASC;
