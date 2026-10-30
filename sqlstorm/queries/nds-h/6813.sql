WITH high_value_orders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F' 
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
),
high_value_customers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-12-31'
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 50000
),
top_suppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_supply_cost DESC
    LIMIT 10
),
combined_data AS (
    SELECT hvo.o_orderkey, hvc.c_name AS customer_name, ts.s_name AS supplier_name, hvo.total_order_value
    FROM high_value_orders hvo
    JOIN high_value_customers hvc ON hvc.total_spent > 100000
    JOIN lineitem li ON li.l_orderkey = hvo.o_orderkey
    JOIN partsupp ps ON ps.ps_partkey = li.l_partkey
    JOIN top_suppliers ts ON ts.s_suppkey = ps.ps_suppkey
)
SELECT cd.customer_name, cd.supplier_name, SUM(cd.total_order_value) AS total_value
FROM combined_data cd
GROUP BY cd.customer_name, cd.supplier_name
ORDER BY total_value DESC;