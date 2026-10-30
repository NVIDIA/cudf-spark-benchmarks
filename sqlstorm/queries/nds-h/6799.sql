WITH SupplierSales AS (
    SELECT s.s_suppkey, s.s_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name
    FROM SupplierSales s
    ORDER BY s.total_sales DESC
    LIMIT 10
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, c.c_name, c.c_acctbal, l.l_extendedprice, l.l_tax, l.l_discount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
)
SELECT ts.s_name, od.o_orderkey, od.o_orderdate, od.c_name, od.c_acctbal,
       SUM(od.l_extendedprice * (1 - od.l_discount)) AS order_total,
       SUM(od.l_tax) AS total_tax,
       AVG(od.c_acctbal) AS avg_customer_balance
FROM TopSuppliers ts
JOIN OrderDetails od ON ts.s_suppkey = od.o_orderkey
GROUP BY ts.s_name, od.o_orderkey, od.o_orderdate, od.c_name, od.c_acctbal
ORDER BY order_total DESC, ts.s_name;
