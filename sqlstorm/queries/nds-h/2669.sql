WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01' 
      AND o.o_orderdate < DATE '1998-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_nationkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_acctbal,
        SUM(o.o_totalprice) AS total_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
)
SELECT 
    r.r_name AS region,
    COALESCE(SUM(s.total_supply_cost), 0) AS region_total_supply_cost,
    COALESCE(SUM(hv.total_order_value), 0) AS region_high_value_customer_orders,
    AVG(o_rank.order_rank) AS average_order_rank
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN SupplierStats s ON n.n_nationkey = s.s_nationkey
LEFT JOIN HighValueCustomers hv ON n.n_nationkey = hv.c_custkey
LEFT JOIN RankedOrders o_rank ON hv.c_custkey = o_rank.o_orderkey
GROUP BY r.r_name
ORDER BY region;