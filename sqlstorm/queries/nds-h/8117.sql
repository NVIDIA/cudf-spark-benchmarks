WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name,
           RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
TotalSales AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY o.o_orderkey
),
SupplierSales AS (
    SELECT rs.s_suppkey, rs.s_name, ts.total_sales
    FROM RankedSuppliers rs
    JOIN partsupp ps ON rs.s_suppkey = ps.ps_suppkey
    JOIN TotalSales ts ON ps.ps_partkey = ts.o_orderkey
)
SELECT rs.nation_name, COUNT(DISTINCT ss.s_suppkey) AS supplier_count,
       AVG(ss.total_sales) AS avg_sales_per_supplier, 
       SUM(ss.total_sales) AS total_sales_per_nation
FROM SupplierSales ss
JOIN RankedSuppliers rs ON ss.s_suppkey = rs.s_suppkey
WHERE rs.rank = 1
GROUP BY rs.nation_name
ORDER BY total_sales_per_nation DESC
LIMIT 10;