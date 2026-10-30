
WITH  cte_supplier_orders AS (
    SELECT s.s_suppkey, s.s_name, COUNT(o.o_orderkey) AS order_count
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY s.s_suppkey, s.s_name
),
ranked_orders AS (
    SELECT s.s_suppkey, s.s_name, COUNT(o.o_orderkey) AS order_count,
           RANK() OVER (ORDER BY COUNT(o.o_orderkey) DESC) AS order_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY s.s_suppkey, s.s_name
),
top_suppliers AS (
    SELECT cte.s_suppkey, cte.s_name, cte.order_count
    FROM cte_supplier_orders cte
    JOIN ranked_orders r ON cte.s_suppkey = r.s_suppkey
    WHERE r.order_rank <= 10
),
part_supplier_details AS (
    SELECT p.p_partkey, p.p_name, s.s_suppkey, s.s_name, ps.ps_availqty
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE ps.ps_availqty IS NOT NULL
),
final_results AS (
    SELECT t.s_name, t.order_count, COUNT(psd.p_partkey) AS parts_supplied
    FROM top_suppliers t
    LEFT JOIN part_supplier_details psd ON t.s_suppkey = psd.s_suppkey
    GROUP BY t.s_name, t.order_count
)
SELECT fr.s_name, fr.order_count, 
       COALESCE(fr.parts_supplied, 0) AS parts_supplied,
       SUBSTRING(s.s_comment, 1, 10) AS comment_excerpt
FROM final_results fr
LEFT JOIN supplier s ON fr.s_name = s.s_name
LEFT JOIN orders o ON s.s_suppkey = o.o_custkey
WHERE fr.order_count > 5 OR fr.parts_supplied IS NULL
ORDER BY fr.order_count DESC, fr.s_name;
