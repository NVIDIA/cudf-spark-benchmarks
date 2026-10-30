WITH  RegionalSupplier AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name, 
           RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank 
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name,
           RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal BETWEEN 500 AND 1000
),
AggregatedSales AS (
    SELECT l.l_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           AVG(l.l_quantity) AS avg_quantity
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY l.l_partkey
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, p.p_comment, 
           EXISTS (SELECT 1 FROM AggregatedSales a WHERE a.l_partkey = p.p_partkey) AS has_sales
    FROM part p
    WHERE p.p_retailprice > (
        SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size < 20
    )
)
SELECT r.nation_name, COUNT(DISTINCT fs.p_partkey) AS parts_count,
       SUM(fs.p_retailprice * CASE WHEN fs.has_sales THEN 1 ELSE 0 END) AS total_retail_value
FROM RegionalSupplier r
LEFT JOIN FilteredParts fs ON r.s_suppkey = fs.p_partkey
WHERE r.rank <= 5
GROUP BY r.nation_name
ORDER BY total_retail_value DESC
LIMIT 10;
