
WITH PartDetails AS (
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
        s.s_name AS supplier_name,
        s.s_address AS supplier_address,
        n.n_name AS nation_name
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
AggregatedData AS (
    SELECT 
        p.p_mfgr AS mfgr,
        COUNT(DISTINCT p.p_partkey) AS unique_parts,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(p.p_retailprice) AS avg_retail_price
    FROM 
        PartDetails p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_mfgr
),
FinalReport AS (
    SELECT 
        ad.mfgr,
        ad.unique_parts,
        ad.total_available_qty,
        ad.avg_retail_price,
        CASE 
            WHEN ad.avg_retail_price < 100 THEN 'Budget'
            WHEN ad.avg_retail_price BETWEEN 100 AND 300 THEN 'Mid-range'
            ELSE 'Premium'
        END AS price_category
    FROM 
        AggregatedData ad
)
SELECT 
    fr.mfgr,
    fr.unique_parts,
    fr.total_available_qty,
    fr.avg_retail_price,
    fr.price_category
FROM 
    FinalReport fr
WHERE 
    fr.total_available_qty > 0
ORDER BY 
    fr.avg_retail_price DESC, 
    fr.unique_parts ASC;
