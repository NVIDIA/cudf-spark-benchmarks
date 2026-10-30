WITH RegionalSupplier AS (
    SELECT n.n_name AS nation_name, r.r_name AS region_name, s.s_suppkey, s.s_name, s.s_acctbal
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > (
        SELECT AVG(s_inner.s_acctbal)
        FROM supplier s_inner
        WHERE s_inner.s_nationkey = s.s_nationkey
    )
),
PartSales AS (
    SELECT ps.ps_partkey, SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales
    FROM lineitem li
    JOIN partsupp ps ON li.l_partkey = ps.ps_partkey
    WHERE li.l_shipdate >= '1997-01-01'
    GROUP BY ps.ps_partkey
    HAVING SUM(li.l_discount) IS NULL OR SUM(li.l_discount) < 0.10
),
TopParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_type, 
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY ps.total_sales DESC) AS sales_rank
    FROM part p
    JOIN PartSales ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_size BETWEEN 5 AND 15
)
SELECT t.p_name, t.p_brand, t.sales_rank, rs.nation_name, rs.region_name, rs.s_name, rs.s_acctbal
FROM TopParts t
LEFT OUTER JOIN RegionalSupplier rs ON t.p_brand = rs.nation_name
WHERE rs.s_suppkey IS NULL OR rs.s_acctbal > (
    SELECT COALESCE(AVG(s_acctbal), 0)
    FROM RegionalSupplier
)
ORDER BY t.sales_rank, rs.region_name, t.p_name;