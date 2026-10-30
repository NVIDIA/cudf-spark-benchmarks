WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        r.r_name AS region_name,
        COALESCE(RO.total_price, 0) AS total_ordered
    FROM customer c
    LEFT JOIN RankedOrders RO ON c.c_custkey = RO.o_orderkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        AVG(s.s_acctbal) AS average_acct_balance
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
)
SELECT 
    co.c_name AS customer_name,
    co.total_ordered,
    ss.average_acct_balance,
    COALESCE(ss.total_supply_cost, 0) AS total_supply_cost,
    CASE 
        WHEN co.total_ordered > 1000 THEN 'High'
        WHEN co.total_ordered BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS order_priority
FROM CustomerOrders co
FULL OUTER JOIN SupplierStats ss ON co.c_custkey = ss.s_suppkey
WHERE co.total_ordered IS NOT NULL OR ss.total_supply_cost IS NOT NULL
ORDER BY co.total_ordered DESC NULLS LAST, ss.average_acct_balance DESC;
