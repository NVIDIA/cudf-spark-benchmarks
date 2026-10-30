WITH SupplierCost AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
), 
CustomerOrderCounts AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
), 
LineItemsByStatus AS (
    SELECT 
        l.l_returnflag,
        COUNT(*) AS lineitem_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_returnflag
) 
SELECT 
    r.r_name,
    SUM(SC.total_supply_cost) AS regional_total_supply_cost,
    COC.order_count,
    LBS.lineitem_count,
    LBS.total_revenue
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN SupplierCost SC ON s.s_suppkey = SC.s_suppkey
JOIN CustomerOrderCounts COC ON COC.c_custkey = s.s_suppkey
JOIN lineitem l ON s.s_suppkey = l.l_suppkey
JOIN LineItemsByStatus LBS ON l.l_returnflag = LBS.l_returnflag
WHERE r.r_name = 'ASIA'
GROUP BY r.r_name, COC.order_count, LBS.lineitem_count, LBS.total_revenue
ORDER BY regional_total_supply_cost DESC;
