
WITH RankedParts AS (
    SELECT 
        p_partkey, 
        p_name, 
        p_brand, 
        p_type,
        LENGTH(p_name) AS name_length,
        LOWER(p_name) AS lower_name,
        ROW_NUMBER() OVER (PARTITION BY p_brand ORDER BY LENGTH(p_name) DESC) AS brand_rank
    FROM part
),
FilteredParts AS (
    SELECT 
        p_partkey, 
        p_name, 
        p_brand, 
        p_type
    FROM RankedParts
    WHERE brand_rank <= 5
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COALESCE(SUBSTRING(s.s_comment, 1, 5), '') AS comment_snippet
    FROM supplier s
    WHERE s.s_acctbal > 1000.00
),
PartSupplierInfo AS (
    SELECT 
        fp.p_partkey, 
        fp.p_name, 
        sp.s_name AS supplier_name,
        sp.comment_snippet,
        COUNT(*) AS total_suppliers
    FROM FilteredParts fp
    JOIN partsupp ps ON fp.p_partkey = ps.ps_partkey
    JOIN SupplierDetails sp ON ps.ps_suppkey = sp.s_suppkey
    GROUP BY fp.p_partkey, fp.p_name, sp.s_name, sp.comment_snippet
)
SELECT 
    p.p_partkey, 
    p.p_name,
    p.supplier_name,
    p.comment_snippet,
    p.total_suppliers,
    CONCAT('Supplier: ', p.supplier_name, ' | Part: ', p.p_name, ' | Comment Snippet: ', p.comment_snippet) AS info_summary
FROM PartSupplierInfo p
ORDER BY p.total_suppliers DESC, p.p_name;
