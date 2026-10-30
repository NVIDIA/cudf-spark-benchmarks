
WITH TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_cost DESC
    LIMIT 10
),
CountrySpending AS (
    SELECT c.c_nationkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_nationkey
),
NationSpending AS (
    SELECT n.n_name, cs.total_spent
    FROM nation n
    JOIN CountrySpending cs ON n.n_nationkey = cs.c_nationkey
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
    ORDER BY total_revenue DESC
    LIMIT 5
)
SELECT ts.s_name AS supplier_name, np.n_name AS nation_name, pd.p_name AS part_name, 
       pd.total_revenue, ns.total_spent, ts.total_cost
FROM TopSuppliers ts
JOIN NationSpending np ON np.total_spent > 100000
JOIN PartDetails pd ON pd.total_revenue > 50000
JOIN (SELECT DISTINCT ns.total_spent FROM NationSpending ns WHERE ns.total_spent > 100000) ns ON true
WHERE ts.total_cost < 1000
ORDER BY pd.total_revenue DESC, ns.total_spent DESC;
