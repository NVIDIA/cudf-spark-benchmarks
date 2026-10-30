WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_type
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    r.r_name,
    COUNT(DISTINCT n.n_nationkey) AS total_nations,
    COALESCE(SUM(cp.total_order_value), 0) AS total_customer_value,
    AVG(COALESCE(rp.total_supply_cost, 0)) AS avg_supply_cost
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN CustomerOrders cp ON n.n_nationkey = cp.c_custkey
LEFT JOIN RankedParts rp ON rp.rank <= 5
GROUP BY r.r_name
HAVING COUNT(n.n_nationkey) > 1
ORDER BY total_customer_value DESC
LIMIT 10;
