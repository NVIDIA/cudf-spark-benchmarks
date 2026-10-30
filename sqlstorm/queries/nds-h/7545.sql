WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1996-12-31'
),
TopOrders AS (
    SELECT ro.o_orderkey, ro.o_orderdate, ro.o_totalprice, c.c_nationkey
    FROM RankedOrders ro
    JOIN customer c ON ro.o_orderkey = c.c_custkey
    WHERE ro.rn <= 5
),
OrderDetails AS (
    SELECT ti.o_orderkey, SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_price_after_discount
    FROM TopOrders ti
    JOIN lineitem li ON ti.o_orderkey = li.l_orderkey
    GROUP BY ti.o_orderkey
),
SupplierInfo AS (
    SELECT ps.ps_partkey, ps.ps_supplycost, s.s_nationkey
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE ps.ps_availqty > 0
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, SUM(si.ps_supplycost) AS total_supply_cost
    FROM part p
    JOIN SupplierInfo si ON p.p_partkey = si.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT td.o_orderkey, td.total_price_after_discount, pd.p_partkey, pd.p_name, pd.total_supply_cost
FROM OrderDetails td
JOIN PartDetails pd ON td.o_orderkey = pd.p_partkey
WHERE td.total_price_after_discount > 1000
ORDER BY td.total_price_after_discount DESC, pd.total_supply_cost ASC
LIMIT 10;