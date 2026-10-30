
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= '1996-01-01' AND o.o_orderdate <= '1996-12-31'
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey, c.c_name
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(l.l_linenumber) AS total_lines
    FROM lineitem l
    WHERE l.l_shipdate < '1998-10-01'
    GROUP BY l.l_orderkey
)
SELECT 
    co.c_name,
    co.order_count,
    co.total_spent,
    lo.net_revenue,
    lo.total_lines,
    hvs.total_supply_cost,
    CASE 
        WHEN co.total_spent IS NULL THEN 'No Orders'
        ELSE 'Orders Present'
    END AS order_status,
    RANK() OVER (ORDER BY co.total_spent DESC) AS customer_rank
FROM CustomerOrderDetails co
LEFT JOIN LineItemSummary lo ON co.c_custkey = lo.l_orderkey
LEFT JOIN HighValueSuppliers hvs ON lo.l_orderkey IN (
    SELECT l.l_orderkey
    FROM lineitem l
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    WHERE ps.ps_supplycost > 5000
)
WHERE co.order_count > 0 OR hvs.total_supply_cost IS NOT NULL
ORDER BY co.total_spent DESC, co.c_name;
