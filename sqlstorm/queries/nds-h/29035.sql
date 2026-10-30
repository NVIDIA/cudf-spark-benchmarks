
WITH part_details AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        LENGTH(p.p_comment) AS comment_length,
        REGEXP_REPLACE(LOWER(p.p_comment), '[^a-z]', '') AS sanitized_comment
    FROM 
        part p
),
supplier_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        LENGTH(s.s_comment) AS supplier_comment_length
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
order_totals AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        o.o_orderstatus,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderstatus
)
SELECT 
    pd.p_name,
    pd.p_brand,
    pd.p_type,
    pd.p_size,
    pd.p_retailprice,
    si.s_name AS supplier_name,
    si.nation_name,
    ot.o_orderkey,
    ot.total_price,
    ot.o_orderstatus,
    ot.distinct_parts,
    CONCAT(pd.p_name, ' - ', si.s_name) AS combined_info,
    TRIM(CAST(pd.comment_length + si.supplier_comment_length AS STRING)) || ' chars' AS total_comment_length
FROM 
    part_details pd
JOIN 
    partsupp ps ON pd.p_partkey = ps.ps_partkey
JOIN 
    supplier_info si ON ps.ps_suppkey = si.s_suppkey
JOIN 
    order_totals ot ON ps.ps_partkey = ot.o_orderkey
WHERE 
    pd.p_retailprice > 50.00
ORDER BY 
    pd.p_size DESC, 
    ot.total_price DESC
LIMIT 100;
