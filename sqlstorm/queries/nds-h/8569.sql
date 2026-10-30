WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
RegionalTotals AS (
    SELECT r.r_regionkey, r.r_name, SUM(o.o_totalprice) AS total_region_sales
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY r.r_regionkey, r.r_name
),
FinalReport AS (
    SELECT RS.s_suppkey, RS.s_name, COALESCE(CO.total_order_value, 0) AS customer_order_value, 
           COALESCE(RT.total_region_sales, 0) AS region_sales, 
           RS.total_supply_cost, 
           (COALESCE(CO.total_order_value, 0) - RS.total_supply_cost) AS profit
    FROM RankedSuppliers RS
    LEFT JOIN CustomerOrders CO ON RS.s_suppkey = CO.c_custkey
    LEFT JOIN RegionalTotals RT ON CO.c_custkey = RT.r_regionkey
)
SELECT FR.s_suppkey, FR.s_name, FR.customer_order_value, FR.region_sales, FR.total_supply_cost, FR.profit
FROM FinalReport FR
WHERE FR.profit > 0
ORDER BY FR.profit DESC
LIMIT 10;
