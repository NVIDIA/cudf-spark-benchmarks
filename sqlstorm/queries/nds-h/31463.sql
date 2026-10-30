WITH  RegionalSales AS (
    SELECT n.n_nationkey, n.n_name, SUM(o.o_totalprice) AS total_sales
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY n.n_nationkey, n.n_name
    HAVING SUM(o.o_totalprice) > 10000
    UNION ALL
    SELECT r.r_regionkey, r.r_name, SUM(o.o_totalprice)
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE r.r_name IS NOT NULL
    GROUP BY r.r_regionkey, r.r_name
),
DistinctSales AS (
    SELECT DISTINCT n_name, total_sales
    FROM RegionalSales
),
RankedSales AS (
    SELECT n_name, total_sales, RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM DistinctSales
)
SELECT *
FROM RankedSales
WHERE sales_rank < 10
ORDER BY sales_rank;
