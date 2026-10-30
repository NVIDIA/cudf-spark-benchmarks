
WITH SupplierCosts AS (
    SELECT s.s_suppkey, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
HighValueCustomers AS (
    SELECT c.c_custkey, 
           c.c_name, 
           c.c_acctbal
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
),
RecentOrders AS (
    SELECT o.o_orderkey, 
           o.o_custkey, 
           o.o_totalprice, 
           o.o_orderdate
    FROM orders o
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
),
TopSuppliers AS (
    SELECT s.s_suppkey, 
           s.s_name
    FROM supplier s
    JOIN SupplierCosts sc ON s.s_suppkey = sc.s_suppkey
    WHERE sc.total_cost > (SELECT AVG(total_cost) FROM SupplierCosts)
)
SELECT hvc.c_custkey, 
       hvc.c_name, 
       r.o_orderkey,
       r.o_totalprice, 
       r.o_orderdate, 
       ts.s_name AS top_supplier,
       sc.total_cost AS supplier_cost
FROM HighValueCustomers hvc
JOIN RecentOrders r ON hvc.c_custkey = r.o_custkey
JOIN lineitem li ON r.o_orderkey = li.l_orderkey
JOIN TopSuppliers ts ON li.l_suppkey = ts.s_suppkey
JOIN SupplierCosts sc ON ts.s_suppkey = sc.s_suppkey
ORDER BY hvc.c_custkey, r.o_orderdate DESC;
