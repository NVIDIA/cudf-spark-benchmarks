WITH SupplierSummary AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name
    FROM SupplierSummary s
    WHERE s.total_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierSummary)
),
HighSpendingCustomers AS (
    SELECT c.c_custkey, c.c_name
    FROM CustomerOrders c
    WHERE c.total_spent > 10000
)
SELECT 
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    COUNT(o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales_value,
    RANK() OVER(PARTITION BY s.s_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN HighSpendingCustomers c ON o.o_custkey = c.c_custkey
JOIN TopSuppliers s ON l.l_suppkey = s.s_suppkey
WHERE o.o_orderdate >= DATE '1997-01-01'
  AND o.o_orderstatus = 'O'
GROUP BY s.s_name, c.c_name
HAVING COUNT(o.o_orderkey) >= 5
ORDER BY sales_rank, total_sales_value DESC
LIMIT 10;