
WITH SupplierAgg AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_availqty) AS total_available_qty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrderAgg AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
),
NationSupplier AS (
    SELECT n.n_nationkey, n.n_name, SUM(sa.total_available_qty) AS total_supplier_qty
    FROM nation n
    JOIN SupplierAgg sa ON n.n_nationkey = sa.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
NationCustomer AS (
    SELECT n.n_nationkey, n.n_name, SUM(ca.total_spent) AS total_customer_spent
    FROM nation n
    JOIN CustomerOrderAgg ca ON n.n_nationkey = ca.c_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT ns.n_name AS nation_name, 
       COALESCE(ns.total_supplier_qty, 0) AS total_available_qty,
       COALESCE(nc.total_customer_spent, 0) AS total_spent
FROM NationSupplier ns
FULL OUTER JOIN NationCustomer nc ON ns.n_nationkey = nc.n_nationkey
ORDER BY ns.n_name, nc.n_name;
