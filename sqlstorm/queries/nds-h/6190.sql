WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name
    FROM RankedSuppliers s
    WHERE s.total_supply_cost > (SELECT AVG(total_supply_cost) FROM RankedSuppliers)
    ORDER BY s.total_supply_cost DESC
    LIMIT 10
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    r.r_name AS region_name,
    nt.n_name AS nation_name,
    cs.c_name AS customer_name,
    ts.s_name AS supplier_name,
    COALESCE(SUM(li.l_extendedprice * (1 - li.l_discount)), 0) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM region r
JOIN nation nt ON r.r_regionkey = nt.n_regionkey
JOIN supplier ts ON nt.n_nationkey = ts.s_nationkey
JOIN lineitem li ON li.l_suppkey = ts.s_suppkey
JOIN orders o ON li.l_orderkey = o.o_orderkey
JOIN CustomerOrders cs ON o.o_custkey = cs.c_custkey
WHERE r.r_name IN ('ASIA', 'EUROPE')
AND o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY r.r_name, nt.n_name, cs.c_name, ts.s_name
HAVING COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY total_revenue DESC;