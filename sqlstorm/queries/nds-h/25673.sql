WITH StringStats AS (
    SELECT 
        p.p_name AS part_name,
        LENGTH(p.p_name) AS name_length,
        SUBSTRING(p.p_comment, 1, 10) AS comment_excerpt,
        COUNT(DISTINCT s.s_suppkey) AS num_suppliers,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(s.s_acctbal) AS avg_supplier_balance
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_name, p.p_comment
),
AggregateStats AS (
    SELECT
        AVG(name_length) AS avg_length_of_part_name,
        MAX(num_suppliers) AS max_suppliers_for_a_part,
        MIN(avg_supplier_balance) AS min_supplier_balance
    FROM 
        StringStats
)
SELECT 
    s.avg_length_of_part_name,
    s.max_suppliers_for_a_part,
    s.min_supplier_balance,
    (SELECT COUNT(*) FROM customer WHERE c_mktsegment = 'BUILDING') AS building_segment_customers,
    (SELECT SUM(o.o_totalprice) FROM orders o WHERE o.o_orderstatus = 'O') AS total_open_orders_value
FROM 
    AggregateStats s;
