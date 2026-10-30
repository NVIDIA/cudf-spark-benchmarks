WITH SupplierSales AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * l.l_quantity) AS total_sales
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY s.s_suppkey, s.s_name
),
CustomerSales AS (
    SELECT c.c_custkey, c.c_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, ss.total_sales
    FROM SupplierSales ss
    JOIN supplier s ON ss.s_suppkey = s.s_suppkey
    ORDER BY ss.total_sales DESC
    LIMIT 5
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, cs.total_spent
    FROM CustomerSales cs
    JOIN customer c ON cs.c_custkey = c.c_custkey
    ORDER BY cs.total_spent DESC
    LIMIT 5
)
SELECT t_sup.s_name AS supplier_name, t_cust.c_name AS customer_name, t_sup.total_sales AS supplier_sales, t_cust.total_spent AS customer_spent
FROM TopSuppliers t_sup
CROSS JOIN TopCustomers t_cust
ORDER BY t_sup.total_sales DESC, t_cust.total_spent DESC;