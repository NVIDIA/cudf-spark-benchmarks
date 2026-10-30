WITH FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        LENGTH(p.p_comment) AS comment_length
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 100)
), SupplierComments AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_comment,
        s.s_address,
        LENGTH(s.s_comment) AS supplier_comment_length
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 5000
), JoinedData AS (
    SELECT 
        fp.p_partkey,
        fp.p_name,
        fp.p_size,
        fp.p_container,
        fp.p_retailprice,
        fp.comment_length,
        sc.s_name AS supplier_name,
        sc.s_address AS supplier_address,
        sc.supplier_comment_length
    FROM 
        FilteredParts fp
    LEFT JOIN 
        partsupp ps ON fp.p_partkey = ps.ps_partkey
    LEFT JOIN 
        SupplierComments sc ON ps.ps_suppkey = sc.s_suppkey
)
SELECT 
    jd.p_partkey,
    jd.p_name,
    jd.p_size,
    jd.p_container,
    jd.p_retailprice,
    jd.comment_length,
    jd.supplier_name,
    jd.supplier_address,
    jd.supplier_comment_length,
    CONCAT(jd.p_name, ' - ', jd.supplier_name) AS part_supplier_info
FROM 
    JoinedData jd
WHERE 
    jd.comment_length > 20 AND jd.supplier_comment_length > 50
ORDER BY 
    jd.p_retailprice DESC, 
    jd.p_name ASC 
LIMIT 100;
