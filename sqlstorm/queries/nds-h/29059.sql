
WITH processed_data AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_container,
        p.p_size,
        s.s_name AS supplier_name,
        c.c_name AS customer_name,
        CONCAT(s.s_name, ' supplies ', p.p_name, ' in ', p.p_container) AS supply_info,
        LEFT(p.p_comment, 15) AS short_comment,
        UPPER(p.p_brand) AS upper_brand,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    GROUP BY 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_container, 
        p.p_size, 
        s.s_name, 
        c.c_name,
        p.p_comment
)
SELECT 
    p_partkey,
    p_name,
    supplier_name,
    customer_name,
    short_comment,
    upper_brand,
    order_count,
    REPLACE(supply_info, ' ', '-') AS supply_info_with_dashes
FROM processed_data
WHERE order_count > 5
ORDER BY upper_brand, p_size DESC;
