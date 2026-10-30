WITH RankedSuppliers AS (
    SELECT 
        s_suppkey, 
        s_name, 
        s_acctbal, 
        RANK() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) AS rank
    FROM supplier
),
FilteredParts AS (
    SELECT 
        p_partkey, 
        p_name, 
        p_size, 
        p_retailprice 
    FROM part 
    WHERE p_size IN (SELECT DISTINCT CASE 
                                        WHEN ROUND(AVG(ps_supplycost), 0) IS NULL THEN 0 
                                        ELSE ROUND(AVG(ps_supplycost), 0) 
                                     END 
                     FROM partsupp 
                     WHERE ps_availqty > 0 
                     GROUP BY ps_partkey HAVING COUNT(DISTINCT ps_suppkey) > 1)
),
OrderStatistics AS (
    SELECT 
        o_orderkey, 
        o_totalprice, 
        COUNT(DISTINCT o_custkey) AS cust_count
    FROM orders 
    GROUP BY o_orderkey, o_totalprice
)
SELECT 
    r.r_name AS region_name, 
    p.p_name AS part_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    MAX(CASE WHEN l.l_returnflag = 'R' THEN l_linestatus ELSE NULL END) AS return_status,
    ntile(3) OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_bucket
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN FilteredParts p ON l.l_partkey = p.p_partkey
LEFT JOIN supplier s ON l.l_suppkey = s.s_suppkey
INNER JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE p.p_retailprice BETWEEN 100 AND 500
  AND r.r_name IS NOT NULL
  AND (o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01' 
       OR o.o_orderstatus IN ('O', 'F'))
GROUP BY r.r_name, p.p_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > (
    SELECT AVG(order_totals.total_revenue)
    FROM (
        SELECT 
            SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
        FROM lineitem l
        INNER JOIN orders o ON l.l_orderkey = o.o_orderkey
        GROUP BY o.o_orderkey
    ) AS order_totals
) 
ORDER BY region_name, total_revenue DESC
LIMIT 10;