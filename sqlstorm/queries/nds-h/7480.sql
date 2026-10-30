
WITH SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, p.p_name, ps.ps_supplycost, ps.ps_availqty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_orderstatus
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
),
LineItemSummary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales, COUNT(l.l_orderkey) AS line_count
    FROM lineitem l
    GROUP BY l.l_orderkey
),
RegionSummary AS (
    SELECT n.n_regionkey, r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY n.n_regionkey, r.r_name
)
SELECT 
    sp.s_name AS supplier_name,
    cp.c_name AS customer_name,
    os.total_sales AS total_order_sales,
    os.line_count AS total_line_items,
    rs.r_name AS region_name,
    rs.nation_count AS distinct_nations,
    CAST('1998-10-01' AS DATE) AS report_date
FROM SupplierParts sp
JOIN CustomerOrders cp ON sp.ps_supplycost = cp.o_orderkey 
JOIN LineItemSummary os ON cp.o_orderkey = os.l_orderkey
JOIN RegionSummary rs ON sp.s_suppkey = (SELECT MIN(s2.s_suppkey) FROM supplier s2)
WHERE sp.ps_availqty > 0
ORDER BY sp.s_name, cp.c_name, os.total_sales DESC
LIMIT 100;
