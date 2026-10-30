WITH RecentOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, c.c_nationkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate, c.c_nationkey
),
SupplierSales AS (
    SELECT ps.ps_suppkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_supplier_sales
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_suppkey
),
TopNations AS (
    SELECT n.n_nationkey, SUM(r.total_sales) AS total_sales_by_nation
    FROM RecentOrders r
    JOIN nation n ON r.c_nationkey = n.n_nationkey
    GROUP BY n.n_nationkey
    ORDER BY total_sales_by_nation DESC
    LIMIT 5
)
SELECT s.s_suppkey, s.s_name, s.s_address, s.s_acctbal, ss.total_supplier_sales, tn.total_sales_by_nation
FROM supplier s
JOIN SupplierSales ss ON s.s_suppkey = ss.ps_suppkey
JOIN TopNations tn ON s.s_nationkey = tn.n_nationkey
WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
ORDER BY tn.total_sales_by_nation DESC, ss.total_supplier_sales DESC;