
WITH SupplierInfo AS (
    SELECT s.s_name, s.s_nationkey, SUBSTRING(s.s_comment, POSITION('excellent' IN s.s_comment), LENGTH(s.s_comment)) AS excellent_comment
    FROM supplier s
    WHERE s.s_comment LIKE '%excellent%'
),
NationInfo AS (
    SELECT n.n_nationkey, n.n_name
    FROM nation n
    JOIN SupplierInfo si ON n.n_nationkey = si.s_nationkey
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_type, p.p_brand
    FROM part p
    WHERE p.p_size BETWEEN 10 AND 20
),
OrderLines AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_quantity, l.l_extendedprice, l.l_discount
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
      AND l.l_returnflag = 'N'
),
FinalMetrics AS (
    SELECT 
        ni.n_name,
        COUNT(DISTINCT si.s_name) AS total_suppliers,
        SUM(ol.l_extendedprice * ol.l_quantity * (1 - ol.l_discount)) AS total_revenue,
        AVG(ol.l_extendedprice * ol.l_quantity * (1 - ol.l_discount)) AS avg_revenue_per_order
    FROM OrderLines ol
    JOIN PartDetails pd ON ol.l_partkey = pd.p_partkey
    JOIN SupplierInfo si ON si.s_nationkey = pd.p_partkey
    JOIN NationInfo ni ON ni.n_nationkey = si.s_nationkey
    GROUP BY ni.n_name
)
SELECT 
    n_name,
    total_suppliers,
    total_revenue,
    ROUND(avg_revenue_per_order, 2) AS avg_revenue_per_order
FROM FinalMetrics
ORDER BY total_revenue DESC;
