
WITH HighValueSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier AS s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > (
        SELECT AVG(s_acctbal)
        FROM supplier
    )
), 
RegionalSales AS (
    SELECT n.n_name, SUM(o.o_totalprice) AS total_sales,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM nation AS n
    LEFT JOIN customer AS c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders AS o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_name
), 
TopRegions AS (
    SELECT r.r_name, SUM(rs.total_sales) AS total_region_sales
    FROM region AS r
    JOIN RegionalSales AS rs ON r.r_regionkey = (
        SELECT MAX(n.n_regionkey)
        FROM nation AS n
        WHERE n.n_name IN (SELECT DISTINCT n_name FROM nation)
    )
    GROUP BY r.r_name
)
SELECT p.p_name, 
       COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
       SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
       MAX(s.s_acctbal) AS highest_supplier_account_balance
FROM part AS p
JOIN partsupp AS ps ON p.p_partkey = ps.ps_partkey
JOIN lineitem AS li ON ps.ps_partkey = li.l_partkey
JOIN HighValueSuppliers AS s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN TopRegions AS tr ON s.s_suppkey IN (
    SELECT s.s_suppkey
    FROM supplier AS s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal < (SELECT MAX(s_acctbal) FROM supplier) 
)
WHERE li.l_returnflag = 'N' 
      AND li.l_shipdate >= DATE '1997-01-01' 
      AND li.l_shipdate < DATE '1998-01-01'
GROUP BY p.p_name
HAVING COUNT(DISTINCT s.s_suppkey) > 0 
       AND (SUM(li.l_extendedprice * (1 - li.l_discount)) IS NOT NULL 
            OR SUM(li.l_extendedprice * (1 - li.l_discount)) > 1000)
ORDER BY total_revenue DESC;
