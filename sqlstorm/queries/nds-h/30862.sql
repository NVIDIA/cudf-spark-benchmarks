
WITH  OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        RANK() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
),
SupplierBalance AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(DISTINCT l.l_suppkey) AS supplier_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
),
FinalResults AS (
    SELECT 
        oh.o_orderkey,
        oh.o_orderdate,
        COALESCE(sb.total_supply_value, 0) AS supplier_value,
        hvo.total_order_value,
        hvo.supplier_count,
        CASE 
            WHEN hvo.supplier_count > 3 THEN 'High supplier count'
            WHEN sb.total_supply_value > 10000 THEN 'High supply value'
            ELSE 'Normal'
        END AS order_category
    FROM OrderHierarchy oh
    LEFT JOIN SupplierBalance sb ON oh.o_orderkey = sb.s_suppkey 
    JOIN HighValueOrders hvo ON oh.o_orderkey = hvo.o_orderkey
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT fr.o_orderkey) AS high_value_order_count,
    AVG(fr.total_order_value) AS average_order_value,
    MAX(fr.supplier_value) AS max_supplier_value,
    MIN(fr.supplier_value) AS min_supplier_value
FROM FinalResults fr
JOIN nation n ON fr.o_orderkey = n.n_nationkey 
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE fr.order_category = 'High supplier count'
GROUP BY r.r_name
ORDER BY region_name;
