
WITH part_details AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_type, 
        p.p_size, 
        p.p_retailprice,
        SUBSTRING(p.p_comment, 1, 10) AS short_comment,
        CHAR_LENGTH(p.p_comment) AS comment_length
    FROM 
        part p
), 
supplier_details AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        s.s_acctbal,
        CONCAT(s.s_name, ' (', s.s_suppkey, ')') AS supplier_info
    FROM 
        supplier s
), 
lineitem_summary AS (
    SELECT 
        l.l_partkey, 
        SUM(l.l_quantity) AS total_quantity, 
        AVG(l.l_extendedprice) AS avg_price, 
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_partkey
), 
top_parts AS (
    SELECT 
        pd.p_partkey, 
        pd.p_name, 
        pd.p_brand, 
        pd.p_type, 
        pd.p_retailprice, 
        ls.total_quantity, 
        ls.avg_price
    FROM 
        part_details pd
    JOIN 
        lineitem_summary ls 
    ON 
        pd.p_partkey = ls.l_partkey
    ORDER BY 
        ls.total_quantity DESC
    LIMIT 10
)
SELECT 
    tp.p_partkey, 
    tp.p_name, 
    tp.p_brand, 
    tp.p_type, 
    tp.p_retailprice, 
    tp.total_quantity,
    tp.avg_price,
    CONCAT(sd.supplier_info, ' - ', CAST(sd.s_acctbal AS STRING)) AS supplier_account_info
FROM 
    top_parts tp
JOIN 
    partsupp ps 
ON 
    tp.p_partkey = ps.ps_partkey
JOIN 
    supplier_details sd 
ON 
    ps.ps_suppkey = sd.s_suppkey;
