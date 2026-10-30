
WITH RankedParts AS (
    SELECT 
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank,
        p.p_partkey
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
SupplierCount AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
),
HighValuePartReport AS (
    SELECT 
        rp.p_name,
        rp.p_brand,
        rp.p_retailprice,
        sc.supplier_count
    FROM 
        RankedParts rp
    JOIN 
        SupplierCount sc ON rp.p_partkey = sc.ps_partkey
    WHERE 
        rp.price_rank <= 3
)
SELECT 
    h.p_name,
    h.p_brand,
    h.p_retailprice,
    h.supplier_count,
    CONCAT('Brand: ', h.p_brand, ' | Retail Price: $', CAST(ROUND(h.p_retailprice, 2) AS STRING), ' | Suppliers: ', h.supplier_count) AS summary_info
FROM 
    HighValuePartReport h
ORDER BY 
    h.p_brand, h.p_retailprice DESC;
