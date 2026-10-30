
WITH  supplier_rank AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_nationkey,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
           DENSE_RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
customer_rank AS (
    SELECT c.c_custkey,
           c.c_name,
           c.c_mktsegment,
           DENSE_RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS rank
    FROM customer c
    WHERE c.c_acctbal > 0
),
high_value_orders AS (
    SELECT o.o_orderkey,
           o.o_custkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate > '1995-01-01' AND l.l_returnflag = 'N'
    GROUP BY o.o_orderkey, o.o_custkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
),
completed_orders AS (
    SELECT o.o_orderkey,
           o.o_orderstatus,
           o.o_totalprice,
           COUNT(l.l_orderkey) AS line_count
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus, o.o_totalprice
    HAVING o.o_orderstatus = 'F'
)
SELECT DISTINCT sr.s_name AS Supplier_Name,
                cr.c_name AS Customer_Name,
                SUM(hv.order_value) AS Total_High_Value_Order,
                COALESCE(COUNT(co.o_orderkey), 0) AS Completed_Order_Count,
                CASE WHEN AVG(sr.total_cost) IS NULL THEN 'No Cost' ELSE CAST(AVG(sr.total_cost) AS STRING) END AS Average_Supply_Cost
FROM supplier_rank sr
FULL OUTER JOIN customer_rank cr ON sr.s_nationkey = cr.c_custkey
LEFT JOIN high_value_orders hv ON sr.s_suppkey = hv.o_custkey
LEFT JOIN completed_orders co ON hv.o_orderkey = co.o_orderkey
WHERE (sr.rank = 1 OR cr.rank = 1)
AND (sr.rank IS NOT NULL OR cr.rank IS NOT NULL)
GROUP BY sr.s_name, cr.c_name
ORDER BY Total_High_Value_Order DESC NULLS LAST;
