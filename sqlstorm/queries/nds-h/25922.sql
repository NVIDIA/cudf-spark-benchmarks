WITH PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        LOWER(p.p_comment) AS lowercase_comment,
        REPLACE(p.p_name, 'PART', 'ITEM') AS modified_name
    FROM 
        part p
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        CONCAT('Supplier: ', s.s_name, ' (', s.s_phone, ')') AS supplier_info,
        SUBSTRING(s.s_address, 1, 20) AS short_address
    FROM 
        supplier s
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(l.l_linenumber) AS item_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    pd.p_partkey,
    pd.modified_name,
    pd.lowercase_comment,
    sd.supplier_info,
    sd.short_address,
    lis.total_price,
    lis.item_count
FROM 
    PartDetails pd
JOIN 
    partsupp ps ON pd.p_partkey = ps.ps_partkey
JOIN 
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
JOIN 
    LineItemSummary lis ON ps.ps_partkey = lis.l_orderkey
WHERE 
    pd.p_size BETWEEN 10 AND 50
ORDER BY 
    lis.total_price DESC, 
    pd.p_name ASC
LIMIT 100;
