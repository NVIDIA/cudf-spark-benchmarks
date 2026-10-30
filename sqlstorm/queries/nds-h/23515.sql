
WITH RankedSuppliers AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_acctbal,
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
OrderLineSummary AS (
    SELECT o.o_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total,
           COUNT(*) AS line_item_count,
           MAX(l.l_shipdate) AS latest_shipdate
    FROM orders o
    INNER JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate < '1998-10-01'
    GROUP BY o.o_orderkey
),
HighValueOrders AS (
    SELECT oos.o_orderkey,
           oos.order_total,
           rs.s_name AS supplier_name,
           rs.s_acctbal AS supplier_balance
    FROM OrderLineSummary oos
    LEFT JOIN RankedSuppliers rs ON oos.o_orderkey = (
        SELECT ps.ps_partkey
        FROM partsupp ps
        WHERE ps.ps_supplycost = (SELECT MAX(ps_supplycost) 
                                   FROM partsupp ps2 
                                   WHERE ps2.ps_partkey = ps.ps_partkey)
        LIMIT 1
    )
    WHERE oos.order_total > (
        SELECT AVG(order_total) * 1.5
        FROM OrderLineSummary
    )
)
SELECT hvo.o_orderkey,
       hvo.order_total,
       hvo.supplier_name,
       hvo.supplier_balance,
       CASE WHEN hvo.supplier_balance IS NULL THEN 'Supplier Not Available' 
            ELSE 'Supplier Available' END AS supplier_status,
       CASE WHEN hvo.order_total > 10000 THEN 'High Value' 
            ELSE 'Standard Value' END AS order_type,
       (SELECT COUNT(*) FROM lineitem l2 WHERE l2.l_orderkey = hvo.o_orderkey) AS total_line_items,
       COALESCE(NTH_VALUE(hvo.supplier_name, 2) OVER (ORDER BY hvo.order_total DESC), 'No Second Supplier') AS second_supplier_name
FROM HighValueOrders hvo
ORDER BY hvo.order_total DESC
LIMIT 20;
