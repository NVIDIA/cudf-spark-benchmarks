
WITH SupplierProductCounts AS (
    SELECT s.s_suppkey, s.s_name, COUNT(ps.ps_partkey) AS product_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerSpending AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT s.s_name AS sc_name, sp.product_count
    FROM SupplierProductCounts sp
    JOIN (
        SELECT s.s_suppkey, s.s_name
        FROM supplier s
        ORDER BY s.s_acctbal DESC
        LIMIT 5
    ) s ON sp.s_suppkey = s.s_suppkey
),
TopCustomers AS (
    SELECT c.c_name, c.total_spent
    FROM CustomerSpending c
    JOIN (
        SELECT c.c_custkey
        FROM customer c
        ORDER BY c.c_acctbal DESC
        LIMIT 5
    ) top_c ON c.c_custkey = top_c.c_custkey
)
SELECT tc.c_name AS top_customer, ts.sc_name AS top_supplier, ts.product_count
FROM TopCustomers tc
JOIN TopSuppliers ts ON ts.product_count > 10
ORDER BY tc.total_spent DESC, ts.product_count DESC;
