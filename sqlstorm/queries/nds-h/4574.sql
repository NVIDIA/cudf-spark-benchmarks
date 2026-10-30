
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
),
SupplierCosts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    c.c_name,
    COALESCE(c.total_orders, 0) AS total_orders,
    COALESCE(so.total_supply_cost, 0) AS total_supply_cost,
    RANK() OVER (ORDER BY COALESCE(c.total_orders, 0) DESC, COALESCE(so.total_supply_cost, 0) DESC) AS rank
FROM CustomerOrders c 
LEFT JOIN (
    SELECT 
        sc.ps_partkey,
        SUM(sc.total_supply_cost) AS total_supply_cost
    FROM SupplierCosts sc
    INNER JOIN part p ON sc.ps_partkey = p.p_partkey
    WHERE p.p_size > 50
    GROUP BY sc.ps_partkey
) so ON so.ps_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 0)
WHERE c.c_name LIKE 'A%'
    AND (c.total_orders > 0 OR so.total_supply_cost > 0)
ORDER BY rank
LIMIT 100;
