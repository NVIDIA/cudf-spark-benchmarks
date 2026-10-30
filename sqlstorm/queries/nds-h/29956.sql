WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        CONCAT(p.p_brand, ' ', p.p_mfgr) AS brand_mfgr,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(p.p_retailprice) AS avg_retail_price,
        ROW_NUMBER() OVER (ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_mfgr
),
TopParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.brand_mfgr,
        rp.supplier_count,
        rp.total_supply_cost,
        rp.avg_retail_price
    FROM 
        RankedParts rp
    WHERE 
        rp.rank <= 10
)
SELECT 
    tp.p_partkey,
    tp.p_name,
    tp.brand_mfgr,
    tp.supplier_count,
    tp.total_supply_cost,
    tp.avg_retail_price,
    CASE 
        WHEN tp.avg_retail_price > (SELECT AVG(avg_retail_price) FROM TopParts) THEN 'Above Average'
        ELSE 'Below Average'
    END AS price_comparison
FROM 
    TopParts tp
ORDER BY 
    tp.total_supply_cost DESC;
