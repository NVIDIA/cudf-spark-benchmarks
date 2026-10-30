WITH SupplierSales AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * li.l_quantity) AS total_selling_price,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem li ON ps.ps_partkey = li.l_partkey
    JOIN orders o ON li.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'O' 
    AND li.l_shipdate >= DATE '1997-01-01' 
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        total_selling_price,
        total_orders,
        RANK() OVER (ORDER BY total_selling_price DESC) AS sales_rank
    FROM SupplierSales s
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    ts.s_name AS supplier_name,
    ts.total_selling_price,
    ts.total_orders
FROM TopSuppliers ts
JOIN supplier s ON ts.s_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE ts.sales_rank <= 5 
OR ts.total_orders > (SELECT AVG(total_orders) FROM TopSuppliers)
ORDER BY region_name, total_selling_price DESC;