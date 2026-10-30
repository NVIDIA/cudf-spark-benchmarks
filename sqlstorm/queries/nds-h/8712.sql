
WITH supplier_details AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation_name, s.s_acctbal, COUNT(ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name, s.s_acctbal
),
customer_order_summary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
high_value_suppliers AS (
    SELECT s.s_suppkey, s.s_name, s.nation_name, s.s_acctbal
    FROM supplier_details s
    WHERE s.part_count > 1 AND s.s_acctbal > 500.00
),
high_value_customers AS (
    SELECT c.c_custkey, c.c_name, c.total_spent
    FROM customer_order_summary c
    WHERE c.total_spent > 1000.00
)
SELECT hvs.nation_name, COUNT(DISTINCT hvs.s_suppkey) AS supplier_count, COUNT(DISTINCT hvc.c_custkey) AS customer_count
FROM high_value_suppliers hvs
JOIN high_value_customers hvc ON hvc.total_spent > 500
GROUP BY hvs.nation_name
ORDER BY supplier_count DESC, customer_count DESC
LIMIT 10;
