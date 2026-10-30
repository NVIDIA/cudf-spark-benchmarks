WITH supplier_summary AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS supplier_nation, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
), 
top_suppliers AS (
    SELECT supplier_nation, s_suppkey, s_name, total_supply_cost,
           RANK() OVER (PARTITION BY supplier_nation ORDER BY total_supply_cost DESC) AS supplier_rank
    FROM supplier_summary
),
customer_summary AS (
    SELECT c.c_custkey, c.c_name, n.n_name AS customer_nation, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, n.n_name
),
top_customers AS (
    SELECT customer_nation, c_custkey, c_name, total_spent,
           RANK() OVER (PARTITION BY customer_nation ORDER BY total_spent DESC) AS customer_rank
    FROM customer_summary
)
SELECT ts.supplier_nation, 
       ts.s_suppkey, 
       ts.s_name AS supplier_name,
       tc.customer_nation, 
       tc.c_custkey, 
       tc.c_name AS customer_name,
       ts.total_supply_cost, 
       tc.total_spent
FROM top_suppliers ts
JOIN top_customers tc ON ts.supplier_nation = tc.customer_nation
WHERE ts.supplier_rank <= 5 AND tc.customer_rank <= 5
ORDER BY ts.supplier_nation, ts.total_supply_cost DESC, tc.total_spent DESC;
