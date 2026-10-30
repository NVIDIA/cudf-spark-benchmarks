WITH  SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, p.p_name, p.p_retailprice
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
), RegionalSales AS (
    SELECT n.n_nationkey, n.n_name, r.r_name, SUM(o.o_totalprice) AS total_sales
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_nationkey, n.n_name, r.r_name
), RankedProducts AS (
    SELECT p.p_partkey, p.p_name, AVG(l.l_extendedprice) AS avg_price
    FROM lineitem l
    JOIN part p ON l.l_partkey = p.p_partkey
    WHERE l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY p.p_partkey, p.p_name
), FinalBenchmark AS (
    SELECT rp.p_name, rp.avg_price, ss.s_name, rs.total_sales
    FROM RankedProducts rp
    JOIN SupplierParts ss ON rp.p_partkey = ss.ps_partkey
    JOIN RegionalSales rs ON ss.s_suppkey IN (SELECT DISTINCT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = rp.p_partkey)
)
SELECT fb.p_name, fb.avg_price, fb.s_name, fb.total_sales
FROM FinalBenchmark fb
ORDER BY fb.total_sales DESC, fb.avg_price ASC
LIMIT 100;