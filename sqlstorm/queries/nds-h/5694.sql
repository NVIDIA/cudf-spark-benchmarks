WITH RegionStats AS (
    SELECT r.r_name AS region_name, 
           SUM(c.c_acctbal) AS total_acctbal, 
           COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY r.r_name
),
TopPartStats AS (
    SELECT p.p_name AS part_name, 
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
           AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_name
    ORDER BY supplier_count DESC
    LIMIT 5
),
RecentOrders AS (
    SELECT o.o_orderkey, 
           o.o_orderdate, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT r.region_name, 
       r.total_acctbal, 
       r.supplier_count,
       p.part_name, 
       p.supplier_count AS part_supplier_count, 
       p.avg_supplycost, 
       o.o_orderkey, 
       o.order_value
FROM RegionStats r
JOIN TopPartStats p ON r.supplier_count > p.supplier_count
JOIN RecentOrders o ON o.order_value > r.total_acctbal
ORDER BY r.region_name, p.avg_supplycost DESC, o.order_value DESC;