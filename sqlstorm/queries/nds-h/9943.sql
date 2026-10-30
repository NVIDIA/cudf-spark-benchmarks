WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
RankedPurchases AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate <= DATE '1997-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate
),
TopSuppliers AS (
    SELECT ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY rs.total_supply_value DESC) AS supplier_rank,
           rs.s_suppkey,
           rs.s_name,
           r.r_regionkey
    FROM RankedSuppliers rs
    JOIN nation n ON rs.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_purchase_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY c.c_custkey, c.c_name
)
SELECT ts.s_name AS top_supplier_name,
       tc.c_name AS top_customer_name,
       SUM(tp.total_line_value) AS total_value
FROM TopSuppliers ts
JOIN RankedPurchases tp ON ts.s_suppkey = tp.o_orderkey
JOIN TopCustomers tc ON tp.o_orderkey = tc.c_custkey
WHERE ts.supplier_rank <= 10
GROUP BY ts.s_name, tc.c_name
ORDER BY total_value DESC;