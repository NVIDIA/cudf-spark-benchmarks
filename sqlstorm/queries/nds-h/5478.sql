WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s 
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
), 

CustomerOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderstatus, c.c_nationkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderstatus, c.c_nationkey
), 

RegionNation AS (
    SELECT r.r_regionkey, r.r_name, n.n_nationkey, n.n_name
    FROM region r 
    JOIN nation n ON r.r_regionkey = n.n_regionkey
)

SELECT rn.r_name, cs.c_nationkey, cs.total_revenue, rs.s_name, rs.total_cost
FROM CustomerOrders cs 
JOIN RegionNation rn ON cs.c_nationkey = rn.n_nationkey
JOIN RankedSuppliers rs ON cs.o_custkey = rs.s_nationkey
WHERE rs.total_cost > (SELECT AVG(total_cost) FROM RankedSuppliers) 
AND cs.total_revenue > 10000
ORDER BY rn.r_name, cs.total_revenue DESC;
