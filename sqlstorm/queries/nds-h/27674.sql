WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        s.s_acctbal,
        CONCAT(s.s_name, ' from ', s.s_address, ', ', n.n_name, ', ', r.r_name) AS supplier_info
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_mfgr,
        p.p_retailprice,
        p.p_comment,
        CONCAT(p.p_mfgr, ' - ', p.p_name, ' (', p.p_brand, ')') AS part_info
    FROM part p
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderstatus,
        o.o_orderdate,
        c.c_name AS customer_name,
        CONCAT(o.o_orderkey, ': ', c.c_name, ' - ', o.o_orderstatus) AS order_summary
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
)
SELECT 
    s.supplier_info,
    p.part_info,
    o.order_summary,
    COUNT(li.l_orderkey) AS total_line_items,
    SUM(li.l_extendedprice) AS total_revenue
FROM SupplierDetails s
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN PartDetails p ON ps.ps_partkey = p.p_partkey
JOIN lineitem li ON li.l_partkey = p.p_partkey
JOIN OrderDetails o ON li.l_orderkey = o.o_orderkey
WHERE p.p_retailprice > 100.00 AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY s.supplier_info, p.part_info, o.order_summary
ORDER BY total_revenue DESC, total_line_items DESC;