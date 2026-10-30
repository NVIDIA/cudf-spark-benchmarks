
WITH SupplierSales AS (
    SELECT s.s_suppkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, ss.total_sales
    FROM SupplierSales ss
    JOIN supplier s ON ss.s_suppkey = s.s_suppkey
    ORDER BY ss.total_sales DESC
    LIMIT 10
),
NationDetails AS (
    SELECT n.n_nationkey, n.n_name AS nation_name, r.r_name AS region_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT td.nation_name, td.region_name, ts.s_name, ts.total_sales
FROM TopSuppliers ts
JOIN supplier s ON ts.s_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN NationDetails td ON n.n_nationkey = td.n_nationkey
ORDER BY ts.total_sales DESC, td.nation_name;
