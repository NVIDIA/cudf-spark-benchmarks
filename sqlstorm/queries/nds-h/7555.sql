WITH SupplierSales AS (
    SELECT s.s_suppkey, s.s_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, ss.total_sales
    FROM supplier s
    JOIN SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    ORDER BY ss.total_sales DESC
    LIMIT 10
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
HighSpendingCustomers AS (
    SELECT c.c_custkey, c.c_name, co.total_spent
    FROM customer c
    JOIN CustomerOrders co ON c.c_custkey = co.c_custkey
    WHERE co.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
)
SELECT ts.s_name, hsc.c_name, ts.total_sales, hsc.total_spent
FROM TopSuppliers ts
JOIN HighSpendingCustomers hsc ON ts.s_suppkey IN (
    SELECT ps.ps_suppkey 
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey IN (SELECT c.c_custkey FROM HighSpendingCustomers c))
)
ORDER BY ts.total_sales DESC, hsc.total_spent DESC;
