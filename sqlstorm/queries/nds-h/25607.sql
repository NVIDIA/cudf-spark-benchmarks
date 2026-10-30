WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation_name, r.r_name AS region_name,
           CONCAT(s.s_name, ' from ', n.n_name, ', ', r.r_name, ' - Phone: ', s.s_phone) AS supplier_info
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_type, 
           CONCAT(p.p_name, ' (', p.p_brand, ') - Type: ', p.p_type) AS part_info
    FROM part p
),
OrderInfo AS (
    SELECT o.o_orderkey, c.c_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           CONCAT(c.c_name, ' - Total Revenue: ', SUM(l.l_extendedprice * (1 - l.l_discount))) AS order_summary
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, c.c_name
)
SELECT sd.supplier_info, pd.part_info, oi.order_summary
FROM SupplierDetails sd
JOIN partsupp ps ON sd.s_suppkey = ps.ps_suppkey
JOIN PartDetails pd ON ps.ps_partkey = pd.p_partkey
JOIN OrderInfo oi ON pd.p_partkey = oi.o_orderkey  
WHERE sd.nation_name LIKE 'United%'
ORDER BY sd.region_name, oi.total_revenue DESC;