WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name, 
           RANK() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
), PartSales AS (
    SELECT ps.ps_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    GROUP BY ps.ps_partkey
), RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, ps.total_sales, 
           RANK() OVER (ORDER BY ps.total_sales DESC) AS sales_rank
    FROM part p
    JOIN PartSales ps ON p.p_partkey = ps.ps_partkey
), TopSuppliers AS (
    SELECT s.s_name, rs.nation_name, rs.rank
    FROM RankedSuppliers rs
    JOIN supplier s ON rs.s_suppkey = s.s_suppkey
    WHERE rs.rank <= 5
)
SELECT rp.p_name, rp.p_brand, tp.s_name, tp.nation_name, rp.total_sales
FROM RankedParts rp
JOIN TopSuppliers tp ON rp.p_partkey IN (
    SELECT ps.ps_partkey 
    FROM partsupp ps 
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal > 10000 
)
WHERE rp.sales_rank <= 10
ORDER BY rp.total_sales DESC, tp.nation_name, tp.s_name;
