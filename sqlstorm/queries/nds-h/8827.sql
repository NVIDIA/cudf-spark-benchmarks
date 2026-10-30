WITH SupplierCost AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
LineItemSummary AS (
    SELECT l.l_partkey, SUM(l.l_quantity) AS total_quantity, SUM(l.l_extendedprice - l.l_discount) AS total_sales
    FROM lineitem l
    WHERE l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1998-01-01'
    GROUP BY l.l_partkey
),
PartDetail AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, ps.total_supply_cost, ls.total_sales
    FROM part p
    LEFT JOIN SupplierCost ps ON p.p_partkey = ps.s_suppkey
    LEFT JOIN LineItemSummary ls ON p.p_partkey = ls.l_partkey
)
SELECT cd.c_name AS customer_name, pd.p_name AS part_name, pd.p_brand, pd.total_supply_cost, cd.total_orders, cd.total_spent
FROM CustomerOrders cd
JOIN PartDetail pd ON cd.total_orders > 10
WHERE pd.total_supply_cost IS NOT NULL
ORDER BY cd.total_spent DESC, pd.total_sales DESC
LIMIT 10;