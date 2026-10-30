WITH  top_suppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
order_summary AS (
    SELECT o.o_orderkey, COUNT(l.l_orderkey) AS total_lines, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
),
customer_performance AS (
    SELECT c.c_custkey, c.c_name, SUM(os.total_revenue) AS total_spent
    FROM customer c
    JOIN order_summary os ON c.c_custkey = os.o_orderkey
    GROUP BY c.c_custkey, c.c_name
),
ranked_customers AS (
    SELECT cp.*, RANK() OVER (ORDER BY cp.total_spent DESC) AS rank
    FROM customer_performance cp
)
SELECT tp.s_name, rc.c_name, rc.total_spent
FROM top_suppliers tp
JOIN ranked_customers rc ON tp.total_cost > rc.total_spent
WHERE rc.rank <= 10
ORDER BY tp.total_cost DESC, rc.total_spent ASC;
