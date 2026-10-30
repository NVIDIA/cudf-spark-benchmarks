WITH ProcessedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        CONCAT('Part: ', p.p_name, ' | Type: ', p.p_type) AS formatted_desc,
        UPPER(p.p_comment) AS upper_comment
    FROM part p
    WHERE p.p_size BETWEEN 10 AND 20
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS supplier_nation,
        CONCAT(s.s_name, ' from ', n.n_name) AS supplier_info
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > 5000
),
CompositeInfo AS (
    SELECT 
        pp.formatted_desc,
        pp.upper_comment,
        sd.supplier_info,
        sd.s_suppkey
    FROM ProcessedParts pp
    JOIN partsupp ps ON pp.p_partkey = ps.ps_partkey
    JOIN SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
)
SELECT 
    ci.formatted_desc,
    ci.upper_comment,
    ci.supplier_info,
    COUNT(*) AS supply_count
FROM CompositeInfo ci
GROUP BY 
    ci.formatted_desc,
    ci.upper_comment,
    ci.supplier_info
ORDER BY supply_count DESC;
