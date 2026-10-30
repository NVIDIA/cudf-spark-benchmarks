WITH TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_supply_cost DESC
    LIMIT 10
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_orders
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
NationRegion AS (
    SELECT n.n_nationkey, n.n_name, r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    tr.s_name AS supplier_name,
    co.c_name AS customer_name,
    nr.n_name AS nation_name,
    COALESCE(SUM(lo.l_extendedprice * (1 - lo.l_discount)), 0) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders_count
FROM TopSuppliers tr
JOIN partsupp ps ON tr.s_suppkey = ps.ps_suppkey
JOIN lineitem lo ON ps.ps_partkey = lo.l_partkey
JOIN orders o ON lo.l_orderkey = o.o_orderkey
JOIN customer co ON o.o_custkey = co.c_custkey
JOIN NationRegion nr ON co.c_nationkey = nr.n_nationkey
WHERE lo.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31' AND o.o_orderstatus = 'F'
GROUP BY tr.s_name, co.c_name, nr.n_name
ORDER BY total_revenue DESC;