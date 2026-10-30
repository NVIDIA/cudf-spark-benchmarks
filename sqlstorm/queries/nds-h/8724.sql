
WITH SupplierPartCost AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, ps.ps_supplycost, p.p_name, p.p_brand, p.p_type
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
AverageCost AS (
    SELECT p_brand, p_type, AVG(ps_supplycost) AS avg_cost
    FROM SupplierPartCost
    GROUP BY p_brand, p_type
),
HighCostProducts AS (
    SELECT spc.s_name, spc.p_name, spc.p_brand, spc.p_type, spc.ps_supplycost
    FROM SupplierPartCost spc
    JOIN AverageCost ac ON spc.p_brand = ac.p_brand AND spc.p_type = ac.p_type
    WHERE spc.ps_supplycost > ac.avg_cost
),
CustomerOrders AS (
    SELECT c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
)
SELECT hcp.s_name, hcp.p_name, hcp.p_brand, hcp.p_type, co.c_name, co.o_orderkey, co.o_orderdate, co.o_totalprice
FROM HighCostProducts hcp
JOIN CustomerOrders co ON hcp.p_brand = SUBSTRING(CAST(co.o_orderdate AS STRING), 1, 4)
ORDER BY co.o_totalprice DESC, hcp.ps_supplycost DESC
LIMIT 10;
