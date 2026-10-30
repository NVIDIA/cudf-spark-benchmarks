
WITH RegionalSupplierStats AS (
    SELECT 
        n.n_name AS nation,
        r.r_name AS region,
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_name, r.r_name, s.s_suppkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '1997-01-01'
    GROUP BY o.o_orderkey, c.c_custkey, c.c_name
),
RankedOrders AS (
    SELECT 
        o.o_orderkey AS orderkey,
        o.c_name,
        o.total_price,
        ROW_NUMBER() OVER (PARTITION BY o.c_name ORDER BY o.total_price DESC) AS rn
    FROM OrderDetails o
)
SELECT 
    r.region,
    r.nation,
    COALESCE(o.c_name, 'No Orders') AS customer_name,
    r.total_available,
    r.avg_cost,
    o.total_price
FROM RegionalSupplierStats r
LEFT JOIN RankedOrders o ON r.s_suppkey = o.orderkey
WHERE r.total_available > 1000
AND (r.avg_cost IS NULL OR r.avg_cost < 50.00)
ORDER BY r.region, r.nation, customer_name;
