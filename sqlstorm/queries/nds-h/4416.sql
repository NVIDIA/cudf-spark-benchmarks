
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderdate
),
CustomerTotal AS (
    SELECT c.c_custkey, c.c_name, SUM(ro.total_price) AS total_spent
    FROM customer c
    JOIN RecentOrders ro ON c.c_custkey = ro.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
NationSupplier AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT ns.n_name, ns.supplier_count, COUNT(DISTINCT rs.s_suppkey) AS top_suppliers_count,
       COALESCE(SUM(ct.total_spent), 0) AS total_spending
FROM NationSupplier ns
LEFT JOIN RankedSuppliers rs ON ns.n_nationkey = rs.s_suppkey
LEFT JOIN CustomerTotal ct ON ct.c_custkey = rs.s_suppkey
WHERE rs.rn <= 5
GROUP BY ns.n_name, ns.supplier_count
ORDER BY total_spending DESC, ns.n_name;
