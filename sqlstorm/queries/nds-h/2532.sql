WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
NationalStats AS (
    SELECT n.n_nationkey, n.n_name, SUM(so.total_supplycost) AS nation_supplycost, SUM(co.total_spent) AS nation_total_spent
    FROM nation n
    LEFT JOIN SupplierDetails so ON n.n_nationkey = so.s_nationkey
    LEFT JOIN CustomerOrders co ON n.n_nationkey = co.c_custkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT ns.n_name, ns.nation_supplycost, ns.nation_total_spent,
       RANK() OVER (ORDER BY ns.nation_total_spent DESC) AS spending_rank
FROM NationalStats ns
WHERE ns.nation_supplycost IS NOT NULL AND ns.nation_total_spent IS NOT NULL
  AND ns.nation_supplycost - ns.nation_total_spent > 0
ORDER BY ns.nation_total_spent DESC
LIMIT 10;

