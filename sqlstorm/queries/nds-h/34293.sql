WITH  supply_chain AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, p.p_partkey, p.p_name, ps.ps_availqty,
           ps.ps_supplycost, ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY ps.ps_availqty DESC) as rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_availqty > 0  
),
customer_summary AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
),
nation_summary AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
           SUM(COALESCE(c.total_spent, 0)) AS total_spent
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN customer_summary c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_name
),
ranking AS (
    SELECT ns.n_name, ns.total_suppliers, ns.total_spent,
           RANK() OVER (ORDER BY ns.total_spent DESC) AS rank_by_spent,
           RANK() OVER (ORDER BY ns.total_suppliers DESC) AS rank_by_suppliers
    FROM nation_summary ns
)
SELECT r.n_name, r.total_suppliers, r.total_spent, r.rank_by_spent, r.rank_by_suppliers,
       (SELECT COUNT(*) FROM supply_chain s WHERE s.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)) AS below_avg_supplycost
FROM ranking r
WHERE r.rank_by_spent <= 5 OR r.rank_by_suppliers <= 5
ORDER BY r.total_spent DESC, r.total_suppliers DESC;
