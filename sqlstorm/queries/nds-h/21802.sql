
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > (SELECT AVG(ps_supplycost) FROM partsupp)
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        MAX(o.o_totalprice) AS max_order_price
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
    HAVING COUNT(o.o_orderkey) > 0
),
LineitemStats AS (
    SELECT 
        l.l_orderkey,
        COUNT(*) AS lineitem_count,
        SUM(l.l_extendedprice) AS total_extended_price,
        SUM(l.l_discount) AS total_discount,
        MAX(l.l_shipdate) AS last_ship_date
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    co.c_custkey,
    COALESCE(co.order_count, 0) AS total_orders,
    COALESCE(co.max_order_price, 0) AS highest_order_value,
    rp.s_suppkey,
    rp.s_name,
    rp.s_acctbal,
    hp.p_name,
    hp.total_cost AS part_cost,
    ls.lineitem_count,
    ls.total_extended_price,
    ls.total_discount,
    ls.last_ship_date
FROM CustomerOrders co
FULL OUTER JOIN RankedSuppliers rp ON co.c_custkey = rp.s_suppkey
JOIN HighValueParts hp ON hp.p_partkey = rp.s_suppkey 
LEFT JOIN LineitemStats ls ON ls.l_orderkey = co.c_custkey
WHERE rp.rn = 1 OR rp.s_acctbal IS NULL
ORDER BY total_orders DESC, part_cost DESC, highest_order_value;
