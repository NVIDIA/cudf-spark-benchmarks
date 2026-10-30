WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        s.s_phone,
        s.s_acctbal,
        s.s_comment,
        LENGTH(s.s_comment) AS comment_length
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
PartDetails AS (
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
),
CombinedDetails AS (
    SELECT 
        sd.s_suppkey,
        sd.s_name,
        pd.p_name,
        pd.p_brand,
        pd.p_container,
        pd.p_retailprice,
        sd.comment_length AS supplier_comment_length,
        pd.comment_length AS part_comment_length,
        CONCAT(sd.s_name, ' - ', pd.p_name) AS combined_info
    FROM 
        SupplierDetails sd
    JOIN 
        partsupp ps ON sd.s_suppkey = ps.ps_suppkey
    JOIN 
        PartDetails pd ON ps.ps_partkey = pd.p_partkey
)
SELECT 
    combined_info,
    COUNT(*) AS info_count,
    AVG(supplier_comment_length) AS avg_supplier_comment_length,
    AVG(part_comment_length) AS avg_part_comment_length
FROM 
    CombinedDetails
WHERE 
    LENGTH(combined_info) > 30
GROUP BY 
    combined_info
ORDER BY 
    info_count DESC, avg_supplier_comment_length DESC
LIMIT 10;
