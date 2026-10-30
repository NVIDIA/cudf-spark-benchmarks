
WITH SupplierSales AS (
    SELECT s.s_suppkey, s.s_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name
), RankedSales AS (
    SELECT s.s_suppkey, s.s_name, s.total_sales, RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM SupplierSales s
), Nations AS (
    SELECT n.n_nationkey, n.n_name, n.n_regionkey
    FROM nation n
    WHERE n.n_name IN ('FRANCE', 'GERMANY', 'USA')
), SuppliersInNation AS (
    SELECT rs.s_suppkey, rs.s_name, ns.n_nationkey, ns.n_name
    FROM RankedSales rs
    JOIN supplier s ON rs.s_suppkey = s.s_suppkey
    JOIN Nations ns ON s.s_nationkey = ns.n_nationkey
    WHERE rs.sales_rank <= 10
)
SELECT sin.n_name AS nation, COUNT(sin.s_suppkey) AS supplier_count, SUM(ss.total_sales) AS total_sales
FROM SuppliersInNation sin
JOIN SupplierSales ss ON sin.s_suppkey = ss.s_suppkey
GROUP BY sin.n_name
ORDER BY total_sales DESC;
