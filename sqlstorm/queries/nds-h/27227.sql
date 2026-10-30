WITH PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        SUBSTRING(p.p_name, 1, 10) AS short_name,
        LENGTH(p.p_comment) AS comment_length
    FROM 
        part p
    WHERE 
        p.p_retailprice > 100
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        LENGTH(s.s_comment) AS supplier_comment_length
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 5000
),
JoinedData AS (
    SELECT 
        pd.p_partkey,
        pd.p_name,
        pd.p_brand,
        pd.p_type,
        pd.p_retailprice,
        sd.s_name AS supplier_name,
        sd.nation_name,
        pd.comment_length,
        sd.supplier_comment_length
    FROM 
        PartDetails pd
    JOIN 
        partsupp ps ON pd.p_partkey = ps.ps_partkey
    JOIN 
        SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
)
SELECT 
    jd.p_partkey,
    jd.p_name,
    jd.p_brand,
    jd.p_type,
    jd.p_retailprice,
    jd.supplier_name,
    jd.nation_name,
    CONCAT('Comment Length: ', jd.comment_length, ', Supplier Comment Length: ', jd.supplier_comment_length) AS comments_summary
FROM 
    JoinedData jd
WHERE 
    jd.comment_length > 20
ORDER BY 
    jd.p_retailprice DESC
LIMIT 20;
