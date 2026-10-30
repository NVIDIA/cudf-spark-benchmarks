WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank_order,
        CUME_DIST() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice) AS cumulative_order_dist
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        SUM(ps.ps_availqty) AS total_available_qty,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
TopSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.avg_supply_cost,
        ROW_NUMBER() OVER (ORDER BY ss.avg_supply_cost DESC) AS supplier_rank
    FROM SupplierStats ss
    WHERE ss.avg_supply_cost IS NOT NULL
),
OrderDetails AS (
    SELECT 
        lo.l_orderkey,
        p.p_name,
        lo.l_extendedprice * (1 - lo.l_discount) AS net_price,
        lo.l_returnflag
    FROM lineitem lo
    JOIN part p ON lo.l_partkey = p.p_partkey
),
CustomerOrderSummary AS (
    SELECT 
        ro.o_orderkey,
        ro.c_name,
        COUNT(od.l_orderkey) AS total_items,
        SUM(od.net_price) AS total_net_price
    FROM RankedOrders ro
    LEFT JOIN OrderDetails od ON ro.o_orderkey = od.l_orderkey
    WHERE ro.rank_order <= 5
    GROUP BY ro.o_orderkey, ro.c_name
)
SELECT 
    cus.c_name,
    COUNT(DISTINCT co.o_orderkey) AS order_count,
    SUM(co.total_net_price) AS total_spent,
    s.avg_supply_cost,
    CASE 
        WHEN SUM(co.total_net_price) IS NULL THEN 'No Orders'
        ELSE CAST(SUM(co.total_net_price) AS VARCHAR(50))
    END AS total_spent_display,
    RANK() OVER (ORDER BY SUM(co.total_net_price) DESC) AS spending_rank
FROM customer cus
JOIN CustomerOrderSummary co ON cus.c_custkey = co.o_orderkey
LEFT JOIN TopSuppliers s ON co.o_orderkey = s.s_suppkey
GROUP BY cus.c_name, s.avg_supply_cost
HAVING SUM(co.total_net_price) > (SELECT AVG(total_net_price) FROM CustomerOrderSummary)
OR COUNT(DISTINCT co.o_orderkey) > 10
ORDER BY spending_rank;
