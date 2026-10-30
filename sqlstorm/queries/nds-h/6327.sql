WITH  top_suppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_cost DESC
    LIMIT 10
),
monthly_sales AS (
    SELECT 
        EXTRACT(YEAR FROM o.o_orderdate) AS order_year,
        EXTRACT(MONTH FROM o.o_orderdate) AS order_month,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
    GROUP BY order_year, order_month
),
supplier_performance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        AVG(l.l_quantity) AS avg_quantity
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY s.s_suppkey, s.s_name
)
SELECT 
    ts.s_name,
    ts.total_cost,
    ms.order_year,
    ms.order_month,
    ms.total_sales,
    sp.order_count,
    sp.revenue,
    sp.avg_quantity
FROM top_suppliers ts
JOIN monthly_sales ms ON TRUE
JOIN supplier_performance sp ON ts.s_suppkey = sp.s_suppkey
ORDER BY ts.total_cost DESC, ms.order_year, ms.order_month;