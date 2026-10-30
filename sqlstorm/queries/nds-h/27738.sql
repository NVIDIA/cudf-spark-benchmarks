
WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        s.s_acctbal,
        LENGTH(s.s_comment) AS comment_length
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
PartDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_type,
        p.p_size,
        p.p_retailprice,
        LENGTH(p.p_comment) AS comment_length
    FROM 
        part p
    WHERE 
        p.p_retailprice > 10 AND 
        p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 100)
)
SELECT 
    sd.s_suppkey,
    sd.s_name,
    sd.nation_name,
    sd.region_name,
    pd.p_partkey,
    pd.p_name,
    pd.p_brand,
    pd.p_type,
    pd.p_size,
    pd.p_retailprice,
    sd.comment_length AS supplier_comment_length,
    pd.comment_length AS part_comment_length
FROM 
    SupplierDetails sd
JOIN 
    partsupp ps ON sd.s_suppkey = ps.ps_suppkey
JOIN 
    PartDetails pd ON ps.ps_partkey = pd.p_partkey
WHERE 
    sd.comment_length > 50 AND 
    pd.comment_length > 20
ORDER BY 
    sd.s_name, pd.p_retailprice DESC
LIMIT 100;
