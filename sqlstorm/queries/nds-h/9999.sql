
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, COUNT(p.ps_partkey) AS total_parts
    FROM supplier s
    JOIN partsupp p ON s.s_suppkey = p.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM RankedSuppliers s
    WHERE total_parts > 10
    ORDER BY s.s_acctbal DESC
    LIMIT 5
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 1000
),
SuppliersWithHighOrders AS (
    SELECT ts.s_suppkey, ts.s_name, co.c_custkey, co.c_name
    FROM TopSuppliers ts
    JOIN lineitem l ON ts.s_suppkey = l.l_suppkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN CustomerOrders co ON o.o_custkey = co.c_custkey
)
SELECT swho.s_suppkey, swho.s_name, co.c_custkey, co.c_name, 
       COUNT(DISTINCT o.o_orderkey) AS number_of_orders, 
       SUM(l.l_extendedprice) AS total_sales_value
FROM SuppliersWithHighOrders swho
JOIN lineitem l ON swho.s_suppkey = l.l_suppkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer co ON o.o_custkey = co.c_custkey
GROUP BY swho.s_suppkey, swho.s_name, co.c_custkey, co.c_name
ORDER BY total_sales_value DESC, number_of_orders DESC;
