
WITH SupplierDetails AS (
    SELECT s.s_name AS supplier_name,
           s.s_acctbal AS account_balance,
           n.n_name AS nation_name,
           r.r_name AS region_name,
           s.s_comment AS supplier_comment
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
PartDetails AS (
    SELECT p.p_name AS part_name,
           p.p_brand AS part_brand,
           p.p_retailprice AS retail_price,
           p.p_comment AS part_comment
    FROM part p
),
OrderDetails AS (
    SELECT o.o_orderkey AS order_key,
           COUNT(l.l_orderkey) AS lineitem_count,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
CombinedDetails AS (
    SELECT sd.supplier_name,
           pd.part_name,
           od.order_key,
           od.lineitem_count,
           od.total_revenue
    FROM SupplierDetails sd
    CROSS JOIN PartDetails pd
    LEFT JOIN OrderDetails od ON od.lineitem_count > 10
    ORDER BY sd.supplier_name, od.total_revenue DESC
)
SELECT supplier_name,
       part_name,
       order_key,
       lineitem_count,
       total_revenue,
       CONCAT('Supplier: ', supplier_name, '; Part: ', part_name, '; Order: ', order_key, '; Items: ', lineitem_count, '; Revenue: $', CAST(total_revenue AS DECIMAL(10, 2))) AS info_summary
FROM CombinedDetails
WHERE total_revenue > 10000
LIMIT 100;
