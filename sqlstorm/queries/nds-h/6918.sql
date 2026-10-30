WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopRegions AS (
    SELECT n.n_regionkey, r.r_name, COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY n.n_regionkey, r.r_name
    ORDER BY total_orders DESC
    LIMIT 5
),
SupplierDetails AS (
    SELECT rs.s_suppkey, rs.s_name, tr.r_name, tr.total_orders, rs.total_supply_cost
    FROM RankedSuppliers rs
    JOIN TopRegions tr ON rs.s_suppkey IN (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        JOIN part p ON ps.ps_partkey = p.p_partkey
        WHERE p.p_size > 10
    )
)
SELECT sd.s_suppkey, sd.s_name, sd.r_name, sd.total_orders, sd.total_supply_cost
FROM SupplierDetails sd
ORDER BY sd.total_supply_cost DESC
LIMIT 10;