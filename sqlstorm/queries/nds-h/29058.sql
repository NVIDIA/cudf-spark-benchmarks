
WITH processed_string AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        REPLACE(LOWER(p.p_comment), ' ', '_') AS formatted_comment,
        CONCAT(p.p_brand, ' - ', p.p_type) AS combined_label,
        TRIM(COALESCE(NULLIF(p.p_container, ''), 'unknown')) AS clean_container,
        p.p_retailprice
    FROM 
        part p
    WHERE 
        p.p_retailprice > 100.00
), supplier_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        CONCAT(s.s_name, ' (', n.n_name, ')') AS sup_nation,
        SUBSTRING(s.s_phone, 1, 7) AS short_phone
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 5000.00
), order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        COUNT(li.l_orderkey) AS item_count,
        SUM(li.l_quantity) AS total_quantity
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_totalprice
)
SELECT 
    ps.p_partkey,
    ps.formatted_comment,
    ps.combined_label,
    si.short_phone,
    os.total_quantity,
    os.item_count,
    os.o_totalprice
FROM 
    processed_string ps
JOIN 
    partsupp psupp ON ps.p_partkey = psupp.ps_partkey
JOIN 
    supplier_info si ON psupp.ps_suppkey = si.s_suppkey
JOIN 
    order_summary os ON os.o_totalprice > ps.p_retailprice
WHERE 
    ps.clean_container LIKE 'bottle%'
ORDER BY 
    os.o_totalprice DESC, ps.formatted_comment ASC;
