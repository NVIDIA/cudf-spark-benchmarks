WITH RankedParts AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_retailprice, 
           ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank 
    FROM part p 
    WHERE p.p_size BETWEEN 5 AND 15
), 
SupplierStats AS (
    SELECT s.s_suppkey, 
           COUNT(DISTINCT ps.ps_partkey) AS part_count, 
           SUM(ps.ps_supplycost) AS total_supply_cost 
    FROM supplier s 
    INNER JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    GROUP BY s.s_suppkey 
), 
CustomerOrders AS (
    SELECT o.o_orderkey, 
           o.o_totalprice, 
           o.o_orderdate, 
           c.c_name, 
           DENSE_RANK() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS rank 
    FROM orders o 
    JOIN customer c ON o.o_custkey = c.c_custkey 
    WHERE o.o_orderstatus IN ('F', 'P') 
), 
HighValueOrders AS (
    SELECT co.o_orderkey, 
           co.o_totalprice, 
           co.o_orderdate, 
           co.c_name 
    FROM CustomerOrders co 
    WHERE co.rank <= 5 
), 
TotalLineItems AS (
    SELECT l.l_orderkey, 
           SUM(l.l_quantity * l.l_extendedprice * (1 - l.l_discount)) AS total_value 
    FROM lineitem l 
    GROUP BY l.l_orderkey
) 
SELECT r.r_name, 
       COALESCE(SUM(s.total_supply_cost), 0) AS total_supply_cost, 
       AVG(hvo.o_totalprice) AS avg_order_value, 
       COUNT(DISTINCT rp.p_partkey) AS popular_parts_count 
FROM region r 
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey 
LEFT JOIN supplierstats s ON n.n_nationkey = s.s_suppkey 
LEFT JOIN highvalueorders hvo ON hvo.o_orderkey IN (SELECT DISTINCT l.l_orderkey FROM lineitem l WHERE l.l_shipdate >= '1997-01-01')
LEFT JOIN rankedparts rp ON rp.p_retailprice > (SELECT AVG(p1.p_retailprice) FROM part p1 WHERE p1.p_size IS NOT NULL) 
WHERE r.r_name IS NOT NULL 
GROUP BY r.r_name 
HAVING COUNT(DISTINCT hvo.o_orderkey) > 0 
ORDER BY r.r_name, total_supply_cost DESC 
LIMIT 10;