WITH RegionSupplier AS (
    SELECT r.r_name AS region_name, s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY r.r_name, s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT region_name, s_suppkey, s_name, total_supply_cost,
           RANK() OVER (PARTITION BY region_name ORDER BY total_supply_cost DESC) AS supplier_rank
    FROM RegionSupplier
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-10-01'
)
SELECT co.c_name AS customer_name, co.o_orderkey, co.o_orderdate, co.o_totalprice,
       ts.region_name, ts.s_name AS top_supplier, ts.total_supply_cost
FROM CustomerOrders co
JOIN TopSuppliers ts ON co.o_orderkey IN (
    SELECT l.l_orderkey
    FROM lineitem l
    WHERE l.l_extendedprice > 1000
)
WHERE ts.supplier_rank = 1
ORDER BY co.o_orderdate DESC, co.o_totalprice DESC;