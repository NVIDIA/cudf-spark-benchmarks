WITH SupplierSales AS (
    SELECT s.s_suppkey, s.s_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name
),
NationSales AS (
    SELECT n.n_name, SUM(ss.total_sales) AS nation_sales
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    GROUP BY n.n_name
),
TopNations AS (
    SELECT n.n_name, ns.nation_sales, RANK() OVER (ORDER BY ns.nation_sales DESC) AS sales_rank
    FROM nation n
    JOIN NationSales ns ON n.n_name = ns.n_name
)
SELECT n.n_name, n.nation_sales
FROM TopNations n
WHERE n.sales_rank <= 5
ORDER BY n.nation_sales DESC;
