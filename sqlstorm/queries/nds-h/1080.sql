
WITH SupplierStats AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
           COUNT(DISTINCT p.p_partkey) AS unique_parts_supplied
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT o.o_orderkey, 
           o.o_totalprice, 
           c.c_nationkey,
           RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_totalprice > 1000
),
NationScores AS (
    SELECT n.n_nationkey, 
           n.n_name, 
           SUM(ss.total_supply_value) AS total_supply_value_by_nation,
           AVG(os.o_totalprice) AS avg_order_value
    FROM nation n
    LEFT JOIN SupplierStats ss ON n.n_nationkey = ss.s_suppkey
    LEFT JOIN OrderStats os ON n.n_nationkey = os.c_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT n.n_name, 
       COALESCE(ns.total_supply_value_by_nation, 0) AS total_supply_value, 
       COALESCE(ns.avg_order_value, 0) AS avg_order_value,
       CASE 
           WHEN COALESCE(ns.avg_order_value, 0) = 0 THEN 'No Orders'
           ELSE 'Orders Exist'
       END AS order_status,
       ROW_NUMBER() OVER (ORDER BY COALESCE(ns.avg_order_value, 0) DESC) AS nation_rank
FROM NationScores ns 
RIGHT OUTER JOIN nation n ON ns.n_nationkey = n.n_nationkey
WHERE n.n_nationkey IS NOT NULL
ORDER BY nation_rank;
