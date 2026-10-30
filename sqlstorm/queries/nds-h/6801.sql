WITH ranked_parts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand
),
top_parts AS (
    SELECT p_name, p_brand, total_supply_cost, 
           ROW_NUMBER() OVER (PARTITION BY p_brand ORDER BY total_supply_cost DESC) AS rank
    FROM ranked_parts
),
customer_orders AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey
),
top_customers AS (
    SELECT c.c_custkey, c.c_name, co.order_count, co.total_spent,
           ROW_NUMBER() OVER (ORDER BY co.total_spent DESC) AS rank
    FROM customer_orders co
    JOIN customer c ON co.c_custkey = c.c_custkey
)
SELECT tc.c_name, tc.order_count, tc.total_spent, tp.p_name, tp.p_brand, tp.total_supply_cost
FROM top_customers tc
JOIN top_parts tp ON tc.order_count > 10
WHERE tc.rank <= 10 AND tp.rank <= 5
ORDER BY tc.total_spent DESC, tp.total_supply_cost DESC;
