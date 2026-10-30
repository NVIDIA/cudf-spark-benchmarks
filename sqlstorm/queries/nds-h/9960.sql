WITH NationwideSuppliers AS (
    SELECT s.s_suppkey, s.s_name, n.n_name, r.r_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name, r.r_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, n.n_name, SUM(ps.ps_availqty) AS total_available_qty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE ps.ps_availqty > 100
    GROUP BY s.s_suppkey, s.s_name, n.n_name
    HAVING SUM(ps.ps_availqty) > 500
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
    HAVING COUNT(o.o_orderkey) > 10
)
SELECT ns.s_name AS supplier_name, 
       ns.n_name AS nation_name, 
       ns.r_name AS region_name, 
       COUNT(DISTINCT o.o_orderkey) AS order_count, 
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM NationwideSuppliers ns
JOIN TopSuppliers ts ON ns.s_suppkey = ts.s_suppkey
JOIN lineitem l ON l.l_suppkey = ns.s_suppkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN HighValueCustomers hv ON o.o_custkey = hv.c_custkey
GROUP BY ns.s_name, ns.n_name, ns.r_name
ORDER BY total_revenue DESC
LIMIT 10;
