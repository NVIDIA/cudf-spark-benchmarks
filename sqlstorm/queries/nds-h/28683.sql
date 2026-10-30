WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        s.s_address,
        COUNT(DISTINCT ps.ps_partkey) AS product_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, s.s_address
),
ProductDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        LENGTH(p.p_comment) AS comment_length
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
),
SupplierProductCounts AS (
    SELECT 
        sd.s_suppkey,
        sd.s_name,
        sd.nation_name,
        COUNT(DISTINCT pd.p_partkey) AS unique_product_count,
        SUM(pd.comment_length) AS total_comment_length
    FROM 
        SupplierDetails sd
    JOIN 
        partsupp ps ON sd.s_suppkey = ps.ps_suppkey
    JOIN 
        ProductDetails pd ON ps.ps_partkey = pd.p_partkey
    GROUP BY 
        sd.s_suppkey, sd.s_name, sd.nation_name
)
SELECT 
    s.s_name AS supplier_name,
    s.nation_name,
    p.unique_product_count,
    p.total_comment_length,
    s.product_count AS total_products_provided,
    s.total_supply_value AS total_supply_value,
    p.unique_product_count * 1.0 / NULLIF(s.product_count, 0) AS product_ratio
FROM 
    SupplierDetails s
JOIN 
    SupplierProductCounts p ON s.s_suppkey = p.s_suppkey
ORDER BY 
    product_ratio DESC
LIMIT 10;
