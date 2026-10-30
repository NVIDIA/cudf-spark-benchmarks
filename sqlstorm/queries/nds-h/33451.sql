WITH  SupplierCTE AS (
    SELECT s_suppkey, s_name, s_acctbal, s_comment, 
           ROW_NUMBER() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) AS rank
    FROM supplier
),
TopSuppliers AS (
    SELECT * FROM SupplierCTE WHERE rank <= 5
),
Sales AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY o.o_orderkey
),
SupplierSales AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(li.l_extendedprice * (1 - li.l_discount)) AS supplier_total_sales
    FROM partsupp ps
    JOIN lineitem li ON ps.ps_partkey = li.l_partkey
    JOIN TopSuppliers ts ON ps.ps_suppkey = ts.s_suppkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey
)
SELECT p.p_name, 
       COALESCE(ss.supplier_total_sales, 0) AS total_sales_by_supplier,
       (SELECT COUNT(*) FROM orders o WHERE o.o_orderkey IN (SELECT o_orderkey FROM Sales)) AS total_orders,
       r.r_name, 
       SUM(CASE WHEN l.l_shipmode = 'AIR' THEN l.l_quantity ELSE 0 END) AS air_shipments,
       SUM(l.l_discount) AS total_discount 
FROM part p
LEFT JOIN SupplierSales ss ON p.p_partkey = ss.ps_partkey
LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN nation n ON n.n_nationkey = ss.ps_suppkey
LEFT JOIN region r ON r.r_regionkey = n.n_regionkey
WHERE p.p_size > 10 AND 
      (p.p_container IN ('BOX', 'PACKAGE') OR p.p_retailprice IS NULL)
GROUP BY p.p_name, ss.supplier_total_sales, r.r_name
HAVING SUM(l.l_quantity) > 1000
ORDER BY total_sales_by_supplier DESC, p.p_name;