
WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_totalprice > 100
    GROUP BY c.c_custkey, c.c_name
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
),
RegionStats AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(si.total_supply_cost) AS total_supply_cost
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN SupplierInfo si ON n.n_name = si.nation
    GROUP BY r.r_name
)
SELECT 
    r.r_name,
    rs.nation_count,
    rs.total_supply_cost,
    ci.c_name,
    ci.total_orders,
    ci.total_spent,
    hvo.order_value
FROM RegionStats rs
JOIN region r ON rs.r_name = r.r_name
LEFT JOIN CustomerOrders ci ON ci.total_spent = (
    SELECT MAX(total_spent) 
    FROM CustomerOrders 
    WHERE total_orders > 5
) 
LEFT JOIN HighValueOrders hvo ON hvo.o_orderkey = (
    SELECT MAX(o_orderkey)
    FROM HighValueOrders
) 
ORDER BY r.r_name, ci.total_orders DESC, hvo.order_value DESC;
