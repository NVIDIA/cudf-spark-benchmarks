WITH string_combination AS (
    SELECT 
        CONCAT(s_name, ' from ', s_address, ', ', n_name, ' region') AS supplier_info,
        CONCAT(p_name, ' - ', p_brand, ' (', p_type, '), Price: ', p_retailprice) AS part_details,
        c_name AS customer_name,
        CONCAT('Order Date: ', o_orderdate, ', Total Price: ', o_totalprice) AS order_info
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN orders o ON ps.ps_partkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
)
SELECT 
    COUNT(*) AS total_records,
    MIN(supplier_info) AS example_supplier_info,
    MIN(part_details) AS example_part_details,
    MIN(customer_name) AS example_customer_name,
    MIN(order_info) AS example_order_info
FROM string_combination
WHERE LENGTH(supplier_info) > 0
AND LENGTH(part_details) > 0
AND LENGTH(customer_name) > 0
AND LENGTH(order_info) > 0
GROUP BY LENGTH(supplier_info), LENGTH(part_details), LENGTH(customer_name), LENGTH(order_info)
ORDER BY total_records DESC;
