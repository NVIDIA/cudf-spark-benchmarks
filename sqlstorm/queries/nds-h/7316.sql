
WITH RankedSupplier AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, rs.total_supply_cost
    FROM RankedSupplier rs
    JOIN supplier s ON rs.s_suppkey = s.s_suppkey
    WHERE rs.total_supply_cost > (
        SELECT AVG(total_supply_cost)
        FROM RankedSupplier
    )
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) > 5
),
RegionSales AS (
    SELECT r.r_regionkey, r.r_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY r.r_regionkey, r.r_name
)
SELECT c.c_name, ts.s_name, r.r_name, SUM(r.total_sales) AS region_total_sales
FROM CustomerOrders c
JOIN TopSuppliers ts ON c.c_custkey = ts.s_suppkey
JOIN RegionSales r ON ts.s_suppkey = r.r_regionkey
GROUP BY c.c_name, ts.s_name, r.r_name
ORDER BY region_total_sales DESC
LIMIT 10;
