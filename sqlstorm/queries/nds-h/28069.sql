WITH region_summary AS (
    SELECT r.r_name AS region_name,
           COUNT(DISTINCT n.n_nationkey) AS nation_count,
           SUM(s.s_acctbal) AS total_supplier_balance
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name
),
part_summary AS (
    SELECT p.p_name AS part_name,
           SUM(CASE WHEN ps.ps_availqty > 0 THEN ps.ps_availqty ELSE 0 END) AS total_available_quantity,
           AVG(p.p_retailprice) AS average_retail_price
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_name
),
customer_order_summary AS (
    SELECT c.c_name AS customer_name,
           COUNT(o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_name
)
SELECT rs.region_name,
       ps.part_name,
       cs.customer_name,
       rs.nation_count,
       rs.total_supplier_balance,
       ps.total_available_quantity,
       ps.average_retail_price,
       cs.total_orders,
       cs.total_spent
FROM region_summary rs
JOIN part_summary ps ON rs.nation_count > 5
JOIN customer_order_summary cs ON cs.total_orders > 10
ORDER BY rs.region_name, ps.average_retail_price DESC, cs.total_spent DESC;
