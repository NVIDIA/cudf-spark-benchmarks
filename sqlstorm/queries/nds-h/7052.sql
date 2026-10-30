
WITH SupplierCost AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT o.o_custkey, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM orders o
    GROUP BY o.o_custkey
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_quantity) AS total_quantity
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT n.n_name, r.r_name, sc.s_name, pd.p_name, 
       os.order_count, os.total_spent, pd.total_quantity,
       ROUND(sc.total_cost, 2) AS total_supply_cost
FROM nation n
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN customer c ON n.n_nationkey = c.c_nationkey
JOIN OrderStats os ON c.c_custkey = os.o_custkey
JOIN SupplierCost sc ON c.c_nationkey = sc.s_suppkey
JOIN partsupp ps ON sc.s_suppkey = ps.ps_suppkey
JOIN PartDetails pd ON ps.ps_partkey = pd.p_partkey
WHERE r.r_name = 'ASIA' 
      AND os.total_spent > 10000 
      AND pd.total_quantity >= 50
ORDER BY os.total_spent DESC, pd.total_quantity DESC
LIMIT 100;
