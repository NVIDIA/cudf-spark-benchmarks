
WITH  SupplierRevenue AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name
),
HighValueRegions AS (
    SELECT n.n_regionkey, 
           r.r_name,
           SUM(o.o_totalprice) AS region_total
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_regionkey, r.r_name
    HAVING SUM(o.o_totalprice) > 1000000
),
FilteredSuppliers AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           COALESCE(sr.total_revenue, 0) AS total_revenue
    FROM supplier s
    LEFT JOIN SupplierRevenue sr ON s.s_suppkey = sr.s_suppkey
)

SELECT f.s_suppkey, 
       f.s_name, 
       f.total_revenue, 
       r.r_name,
       COALESCE(r.r_name, 'No Region') AS region_name
FROM FilteredSuppliers f
FULL OUTER JOIN HighValueRegions r ON f.total_revenue > r.region_total
WHERE f.total_revenue > (SELECT AVG(total_revenue) FROM FilteredSuppliers)
   OR r.region_total < (SELECT AVG(region_total) FROM HighValueRegions)
ORDER BY f.total_revenue DESC NULLS LAST, r.r_name ASC;
