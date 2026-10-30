
WITH FilteredParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_type, 
        p.p_size, 
        p.p_retailprice, 
        TRIM(p.p_comment) AS trimmed_comment 
    FROM 
        part p 
    WHERE 
        LENGTH(p.p_name) > 10 
        AND p.p_retailprice > 100 
),
SuppliersWithComments AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        REPLACE(s.s_comment, 'damaged', 'damag') AS modified_comment 
    FROM 
        supplier s 
    WHERE 
        POSITION('XYZ' IN s.s_name) > 0 
),
CustomerInfo AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        INITCAP(c.c_address) AS formatted_address, 
        CONCAT(TRIM(c.c_mktsegment), '-', TRIM(c.c_comment)) AS market_comment 
    FROM 
        customer c 
    WHERE 
        c.c_acctbal > 500 
)
SELECT 
    pp.p_partkey, 
    pp.p_name, 
    pp.p_brand, 
    pp.p_type, 
    pp.p_size, 
    pp.p_retailprice, 
    sp.s_name AS supplier_name, 
    sp.modified_comment AS supplier_comment, 
    ci.c_name AS customer_name, 
    ci.formatted_address, 
    ci.market_comment 
FROM 
    FilteredParts pp 
JOIN 
    partsupp ps ON pp.p_partkey = ps.ps_partkey 
JOIN 
    SuppliersWithComments sp ON ps.ps_suppkey = sp.s_suppkey 
JOIN 
    orders o ON ps.ps_partkey = o.o_orderkey 
JOIN 
    CustomerInfo ci ON o.o_custkey = ci.c_custkey 
WHERE 
    pp.trimmed_comment LIKE '%quality%' 
    AND pp.p_size IN (10, 20, 30) 
ORDER BY 
    pp.p_retailprice DESC, 
    ci.c_name;
