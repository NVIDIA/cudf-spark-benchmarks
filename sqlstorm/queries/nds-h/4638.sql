
WITH SupplierPart AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_comment IS NOT NULL)
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= DATE '1997-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
),
SupplierRanked AS (
    SELECT SP.*, 
           RANK() OVER (PARTITION BY SP.p_partkey ORDER BY SP.ps_supplycost ASC) AS supply_rank
    FROM SupplierPart SP
)
SELECT OS.o_orderkey, OS.o_orderdate, COALESCE(SR.s_name, 'Unknown Supplier') AS supplier_name,
       COALESCE(SUM(SR.ps_availqty), 0) AS total_available_qty,
       COALESCE(SUM(SR.ps_supplycost), 0) AS total_supply_cost,
       OS.total_revenue
FROM OrderSummary OS
LEFT JOIN SupplierRanked SR ON OS.o_orderkey = SR.p_partkey AND SR.supply_rank = 1
GROUP BY OS.o_orderkey, OS.o_orderdate, SR.s_name, OS.total_revenue
HAVING COALESCE(SUM(SR.ps_availqty), 0) IS NOT NULL OR COALESCE(SUM(SR.ps_supplycost), 0) IS NOT NULL
ORDER BY OS.total_revenue DESC;
