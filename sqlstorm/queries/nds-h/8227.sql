WITH SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name, r.r_name AS region_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
TotalSales AS (
    SELECT l.l_suppkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY l.l_suppkey
),
RankedSuppliers AS (
    SELECT si.s_suppkey, si.s_name, si.nation_name, si.region_name, ts.total_sales,
           RANK() OVER (PARTITION BY si.region_name ORDER BY ts.total_sales DESC) AS sales_rank
    FROM SupplierInfo si
    JOIN TotalSales ts ON si.s_suppkey = ts.l_suppkey
)

SELECT rs.region_name, rs.s_name, rs.total_sales
FROM RankedSuppliers rs
WHERE rs.sales_rank <= 5
ORDER BY rs.region_name, rs.total_sales DESC;