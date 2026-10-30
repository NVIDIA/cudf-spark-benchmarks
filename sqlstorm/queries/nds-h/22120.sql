WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 1 AND 50 AND
        (p.p_comment LIKE '%high%' OR p.p_comment IS NULL)
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    GROUP BY 
        s.s_suppkey, s.s_name
),
FilteredNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        CASE 
            WHEN n.n_name IS NULL THEN 'Unknown' 
            ELSE n.n_name 
        END AS safe_name
    FROM 
        nation n
    WHERE 
        n.n_comment NOT LIKE '%obsolete%'
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    sd.s_name AS supplier_name,
    fn.safe_name AS nation_name,
    RANK() OVER (ORDER BY p.p_retailprice) AS price_rank,
    CASE 
        WHEN p.p_retailprice IS NULL THEN 'No Price'
        ELSE CONCAT('Price: $', CAST(p.p_retailprice AS STRING))
    END AS price_description
FROM 
    RankedParts p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
LEFT JOIN 
    FilteredNations fn ON sd.total_cost > 10000
WHERE 
    (p.rn = 1 OR p.p_retailprice < 10.00)
    AND (sd.total_cost IS NOT NULL OR fn.safe_name IS NOT NULL)
ORDER BY 
    price_rank DESC, 
    p.p_name ASC;
