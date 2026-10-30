WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        s.s_nationkey, 
        s.s_acctbal, 
        s.s_comment, 
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
), 
DistinctProducts AS (
    SELECT DISTINCT 
        p.p_brand, 
        p.p_name, 
        p.p_type, 
        p.p_size, 
        p.p_retailprice
    FROM 
        part p
    WHERE 
        p.p_retailprice > 100.00
), 
SupplierProductDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name AS supplier_name, 
        dp.p_brand, 
        dp.p_name, 
        dp.p_type, 
        dp.p_size, 
        dp.p_retailprice
    FROM 
        RankedSuppliers s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        DistinctProducts dp ON p.p_brand = dp.p_brand
    WHERE 
        s.rank <= 3
)
SELECT 
    spd.supplier_name, 
    COUNT(*) AS total_products, 
    AVG(spd.p_retailprice) AS avg_retail_price
FROM 
    SupplierProductDetails spd
GROUP BY 
    spd.supplier_name
ORDER BY 
    avg_retail_price DESC;
