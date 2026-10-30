WITH  SupplyCostCTE AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_supplycost, ps.ps_availqty,
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
), RankedSuppliers AS (
    SELECT s_name, SUM(ps_supplycost * ps_availqty) AS total_supply_cost
    FROM SupplyCostCTE
    WHERE rn = 1
    GROUP BY s_name
), CustomerOrders AS (
    SELECT c.c_name, SUM(o.o_totalprice) AS total_order_value, c.c_nationkey
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_name, c.c_nationkey
), NationDetails AS (
    SELECT n.n_nationkey, n.n_name, r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
), OrdersWithSuppliers AS (
    SELECT co.c_name, co.total_order_value, nd.n_name AS nation_name, rs.total_supply_cost
    FROM CustomerOrders co
    JOIN NationDetails nd ON co.c_nationkey = nd.n_nationkey
    LEFT JOIN RankedSuppliers rs ON nd.n_name = rs.s_name
)
SELECT ows.c_name, ows.total_order_value, COALESCE(ows.total_supply_cost, 0) AS total_supply_cost,
       (ows.total_order_value - COALESCE(ows.total_supply_cost, 0)) AS profit
FROM OrdersWithSuppliers ows
WHERE ows.total_order_value > (SELECT AVG(total_order_value) FROM CustomerOrders)
ORDER BY profit DESC
LIMIT 10;
