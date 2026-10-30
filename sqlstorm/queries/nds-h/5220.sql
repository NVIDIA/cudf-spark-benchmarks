
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation, 
           ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, c.c_name, r.r_name AS region
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE o.o_totalprice > 1000
),
PartSupplyDetails AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost,
           p.p_name, p.p_mfgr, l.l_quantity
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
)
SELECT r.nation, r.s_name, COUNT(DISTINCT h.o_orderkey) AS total_orders,
       SUM(h.o_totalprice) AS total_value, AVG(r.s_acctbal) AS avg_supplier_balance,
       SUM(ps.ps_availqty) AS total_available_quantity, COUNT(DISTINCT ps.ps_partkey) AS total_parts
FROM RankedSuppliers r
JOIN HighValueOrders h ON r.nation = h.region
JOIN PartSupplyDetails ps ON r.s_suppkey = ps.ps_suppkey
WHERE r.rank <= 3
GROUP BY r.nation, r.s_name
ORDER BY total_value DESC, avg_supplier_balance DESC;
