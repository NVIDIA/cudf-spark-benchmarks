WITH RankedParts AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_retailprice, 
           RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
), SupplierStats AS (
    SELECT s.s_nationkey, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_nationkey
), CustomerOrders AS (
    SELECT c.c_nationkey,
           COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_nationkey
), NationalStats AS (
    SELECT n.n_nationkey,
           n.n_name,
           COALESCE(cs.order_count, 0) AS orders,
           COALESCE(cs.total_order_value, 0) AS order_value,
           COALESCE(ss.total_supplycost, 0) AS supply_cost
    FROM nation n
    LEFT JOIN CustomerOrders cs ON n.n_nationkey = cs.c_nationkey
    LEFT JOIN SupplierStats ss ON n.n_nationkey = ss.s_nationkey
), ExceptionalParts AS (
    SELECT rp.p_partkey, 
           rp.p_name, 
           np.orders,
           np.supply_cost
    FROM RankedParts rp
    JOIN NationalStats np ON rp.p_partkey = np.orders
    WHERE np.orders > 0 AND np.supply_cost IS NOT NULL
)
SELECT ep.p_partkey,
       ep.p_name,
       ep.orders,
       ep.supply_cost,
       CASE 
           WHEN ep.orders > 10 THEN 'High Demand' 
           WHEN ep.orders BETWEEN 5 AND 10 THEN 'Moderate Demand'
           ELSE 'Low Demand' 
       END AS demand_level,
       CONCAT('Part ', ep.p_name, ' has a total supply cost of ', CAST(ep.supply_cost AS STRING), '.')
FROM ExceptionalParts ep 
LEFT JOIN region r ON r.r_regionkey = (SELECT MIN(rg.r_regionkey) 
                                        FROM region rg 
                                        WHERE rg.r_name LIKE '%e%')
ORDER BY demand_level DESC, ep.supply_cost DESC
LIMIT 10;
