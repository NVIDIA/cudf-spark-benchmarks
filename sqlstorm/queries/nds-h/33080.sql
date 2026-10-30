WITH  supply_chain AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost ASC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_availqty > 0
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS order_count,
        ROW_NUMBER() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rnk
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY o.o_orderkey
),
highest_revenue_orders AS (
    SELECT order_summary.o_orderkey, order_summary.total_revenue, sd.supp_name
    FROM order_summary
    LEFT JOIN (
        SELECT 
            s.s_suppkey,
            s.s_name AS supp_name
        FROM supplier s
        JOIN supply_chain sc ON s.s_suppkey = sc.s_suppkey
        WHERE sc.rn = 1
    ) sd ON order_summary.o_orderkey = sd.s_suppkey
    WHERE order_summary.rnk <= 10
)
SELECT 
    o.o_orderkey,
    hs.total_revenue,
    COALESCE(hs.supp_name, 'No Supplier') AS supplier_name
FROM order_summary o
FULL OUTER JOIN highest_revenue_orders hs ON o.o_orderkey = hs.o_orderkey
WHERE o.total_revenue IS NOT NULL OR hs.total_revenue IS NOT NULL
ORDER BY o.o_orderkey;