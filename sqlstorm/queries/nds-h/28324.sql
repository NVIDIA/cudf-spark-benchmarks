WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_size,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 1 AND 100
),
TopBrandParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_brand,
        rp.p_retailprice
    FROM 
        RankedParts rp
    WHERE 
        rp.rank <= 5
),
SupplierCount AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    tbp.p_partkey,
    tbp.p_name,
    tbp.p_brand,
    tbp.p_retailprice,
    sc.supplier_count,
    CONCAT('Part: ', tbp.p_name, ', Brand: ', tbp.p_brand, ' has ', sc.supplier_count, ' suppliers.') AS description
FROM 
    TopBrandParts tbp
JOIN 
    SupplierCount sc ON tbp.p_partkey = sc.ps_partkey
ORDER BY 
    tbp.p_brand, tbp.p_retailprice DESC;
