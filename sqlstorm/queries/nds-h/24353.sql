WITH PartSupplier AS (
    SELECT p.p_partkey, p.p_name, s.s_suppkey, s.s_name, ps.ps_availqty, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE ps.ps_availqty > 0
),
NationRegion AS (
    SELECT n.n_nationkey, n.n_name, r.r_regionkey, r.r_name
    FROM nation n
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent,
           RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS rank_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) > 1
),
MaxSupplyCost AS (
    SELECT ps.ps_partkey, MAX(ps.ps_supplycost) AS max_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT DISTINCT 
    ps.p_name,
    ns.n_name AS supplier_nation,
    co.order_count,
    co.total_spent,
    CASE 
        WHEN co.order_count > 5 THEN 'Frequent Buyer'
        ELSE 'Occasional Buyer'
    END AS buyer_type,
    CASE 
        WHEN ps.ps_supplycost IS NULL THEN 'No Supply'
        ELSE CONCAT('Cost: $', CAST(ps.ps_supplycost AS CHAR(12)))
    END AS supply_cost_info
FROM PartSupplier ps
FULL OUTER JOIN CustomerOrders co ON ps.p_partkey = co.c_custkey
LEFT JOIN NationRegion ns ON ps.p_partkey = ns.n_nationkey
JOIN MaxSupplyCost msc ON ps.p_partkey = msc.ps_partkey AND ps.ps_supplycost = msc.max_supplycost
WHERE (ps.ps_availqty IS NULL OR ps.ps_availqty > 10) 
AND (co.total_spent IS NOT NULL OR co.order_count <= 10)
ORDER BY buyer_type, total_spent DESC;
