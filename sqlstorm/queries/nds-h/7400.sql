
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name,
           ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > (
        SELECT AVG(s_acctbal) FROM supplier
    )
),
HighValueItems AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, ps.ps_availqty, 
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rank
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_availqty < 100
),
CustomerHighlights AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
)
SELECT COALESCE(r.nation_name, 'N/A') AS supplier_nation,
       SUM(h.ps_supplycost * h.ps_availqty) AS total_cost_of_high_value_items,
       COUNT(DISTINCT ch.c_custkey) AS active_customers,
       AVG(ch.total_spent) AS avg_spent_per_customer
FROM RankedSuppliers r
LEFT JOIN HighValueItems h ON r.s_suppkey = h.p_partkey
LEFT JOIN CustomerHighlights ch ON r.s_suppkey = ch.c_custkey
WHERE r.rank = 1
GROUP BY r.nation_name
ORDER BY total_cost_of_high_value_items DESC;
