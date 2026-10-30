WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
),
FilteredParts AS (
    SELECT p.*, AVG(ps.ps_supplycost) OVER (PARTITION BY p.p_partkey) AS avg_supply_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice,
           RANK() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
)
SELECT 
    rf.s_name AS supplier_name,
    fp.p_name AS part_name,
    COALESCE(SUM(li.l_quantity), 0) AS total_quantity,
    COALESCE(SUM(li.l_extendedprice), 0) AS total_revenue,
    COUNT(DISTINCT co.o_orderkey) AS total_orders,
    CASE 
        WHEN COUNT(DISTINCT co.o_orderkey) > 0 THEN AVG(co.o_totalprice)
        ELSE 0 
    END AS avg_order_value
FROM RankedSuppliers rf
JOIN partsupp ps ON rf.s_suppkey = ps.ps_suppkey
JOIN FilteredParts fp ON ps.ps_partkey = fp.p_partkey
LEFT JOIN lineitem li ON fp.p_partkey = li.l_partkey
LEFT JOIN CustomerOrders co ON co.o_orderkey = li.l_orderkey 
WHERE rf.rank = 1 
AND fp.avg_supply_cost < (SELECT AVG(ps2.ps_supplycost) 
                           FROM partsupp ps2)
GROUP BY rf.s_name, fp.p_name
ORDER BY total_revenue DESC, total_quantity DESC
LIMIT 10;
