
WITH SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
RankedParts AS (
    SELECT sp.*, 
           RANK() OVER (PARTITION BY sp.s_suppkey ORDER BY (sp.ps_availqty * sp.ps_supplycost) DESC) AS rank_avail_cost
    FROM SupplierParts sp
),
TotalRevenue AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
TopSuppliers AS (
    SELECT supplier.s_suppkey, supplier.s_name, SUM(tr.total_revenue) AS supplier_revenue
    FROM SupplierParts sp
    JOIN TotalRevenue tr ON sp.p_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_name = 'SomePartName' LIMIT 1)
    JOIN supplier ON sp.s_suppkey = supplier.s_suppkey
    GROUP BY supplier.s_suppkey, supplier.s_name
)
SELECT rs.s_name, COUNT(DISTINCT rp.p_partkey) AS part_count, SUM(rp.ps_availqty) AS total_available_qty, 
       SUM(tr.total_revenue) AS total_revenue_generated
FROM RankedParts rp
JOIN TopSuppliers rs ON rp.s_suppkey = rs.s_suppkey
JOIN TotalRevenue tr ON rs.s_suppkey = rp.s_suppkey
WHERE rp.rank_avail_cost = 1
GROUP BY rs.s_suppkey, rs.s_name
ORDER BY total_revenue_generated DESC
LIMIT 10;
