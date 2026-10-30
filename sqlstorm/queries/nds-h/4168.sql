WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE l.l_shipdate >= DATE '1996-01-01' AND l.l_shipdate < DATE '1996-12-31'
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s_suppkey, s_name, total_sales, order_count
    FROM SupplierSales
    WHERE sales_rank <= 10
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    tu.s_name,
    tu.total_sales,
    cu.c_name,
    cu.total_spent,
    CASE 
        WHEN cu.order_count IS NULL THEN 'No Orders'
        WHEN cu.total_spent > 10000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_status
FROM TopSuppliers tu
LEFT JOIN CustomerOrders cu ON cu.order_count = (
    SELECT MAX(order_count) FROM CustomerOrders
)
ORDER BY tu.total_sales DESC, cu.total_spent DESC
LIMIT 20;