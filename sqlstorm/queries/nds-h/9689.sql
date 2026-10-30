WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_mktsegment,
           ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) as rn
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate >= '1997-01-01'
),
HighValuePartSupp AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM partsupp ps
    GROUP BY ps.ps_partkey
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
PopularParts AS (
    SELECT l.l_partkey, SUM(l.l_quantity) AS total_quantity_sold
    FROM lineitem l
    GROUP BY l.l_partkey
    ORDER BY total_quantity_sold DESC
    LIMIT 10
)
SELECT p.p_name, p.p_brand, p.p_container, p.p_retailprice,
       r.r_name AS region, SUM(rn.o_totalprice) AS total_order_value
FROM part p
JOIN HighValuePartSupp hvps ON p.p_partkey = hvps.ps_partkey
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN RankedOrders rn ON l.l_orderkey = rn.o_orderkey
JOIN supplier s ON l.l_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE p.p_size BETWEEN 10 AND 20
  AND rn.rn <= 5
  AND p.p_type IN (SELECT p_type FROM part WHERE p_size > 15)
GROUP BY p.p_name, p.p_brand, p.p_container, p.p_retailprice, r.r_name
ORDER BY total_order_value DESC;