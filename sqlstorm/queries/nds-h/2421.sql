WITH sales_data AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_linenumber) AS items_count,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY o.o_orderkey
),
supplier_data AS (
    SELECT 
        s.s_suppkey,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS parts_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
high_value_orders AS (
    SELECT 
        sd.o_orderkey,
        sd.total_sales,
        su.avg_supply_cost,
        RANK() OVER (ORDER BY sd.total_sales DESC) AS order_rank
    FROM sales_data sd
    LEFT JOIN supplier_data su ON sd.items_count > su.parts_count
    WHERE sd.total_sales > 1000.00
)
SELECT 
    hd.o_orderkey,
    hd.total_sales,
    COALESCE(hd.avg_supply_cost, 0) AS average_supply_cost,
    hd.order_rank,
    CASE 
        WHEN hd.order_rank <= 10 THEN 'Top 10 Order'
        ELSE 'Other Orders'
    END AS order_category
FROM high_value_orders hd
ORDER BY hd.total_sales DESC
LIMIT 20;