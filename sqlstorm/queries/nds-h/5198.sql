WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
), SupplierRank AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.total_supply_cost,
           RANK() OVER (ORDER BY s.total_supply_cost DESC) AS supply_rank
    FROM RankedSuppliers s
), OrderTotal AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
), CustomerOrder AS (
    SELECT c.c_custkey, c.c_name, SUM(ot.total_order_value) AS total_value
    FROM customer c
    JOIN OrderTotal ot ON c.c_custkey = ot.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT cr.c_custkey, cr.c_name, sr.s_name, sr.total_supply_cost, co.total_value
FROM CustomerOrder co
JOIN SupplierRank sr ON sr.s_suppkey = (SELECT ps.ps_suppkey 
                                          FROM partsupp ps 
                                          JOIN part p ON ps.ps_partkey = p.p_partkey 
                                          WHERE p.p_brand = 'Brand#23' 
                                          ORDER BY ps.ps_supplycost DESC 
                                          LIMIT 1)
JOIN customer cr ON cr.c_custkey = co.c_custkey
WHERE co.total_value > 100000
ORDER BY sr.total_supply_cost DESC, co.total_value DESC;
