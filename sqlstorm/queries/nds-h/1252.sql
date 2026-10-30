
WITH SupplierSales AS (
    SELECT s.s_suppkey, s.s_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_shipdate >= DATE '1995-01-01'
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT ss.s_suppkey, ss.s_name, ROW_NUMBER() OVER (ORDER BY ss.total_sales DESC) AS rank
    FROM SupplierSales ss
)
SELECT cs.c_name, COALESCE(ts.s_name, 'No Supplier') AS supplier_name, cs.order_count
FROM CustomerOrders cs
LEFT JOIN TopSuppliers ts ON cs.order_count > 0 AND ts.rank <= 5
WHERE cs.order_count > (
    SELECT AVG(order_count) FROM CustomerOrders
)
ORDER BY cs.order_count DESC, supplier_name;
