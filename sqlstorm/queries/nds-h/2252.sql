WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS parts_count
    FROM 
        supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
), OrderDetails AS (
    SELECT 
        o.o_orderkey,
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS item_count,
        RANK() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= '1997-01-01'
    GROUP BY o.o_orderkey, c.c_custkey
), RevenueStats AS (
    SELECT 
        ods.o_orderkey,
        ods.total_revenue,
        ss.s_suppkey,
        ss.total_available_quantity,
        ss.avg_supply_cost,
        ss.parts_count,
        ROW_NUMBER() OVER (ORDER BY ods.total_revenue DESC) AS revenue_rank
    FROM 
        OrderDetails ods
    LEFT JOIN SupplierSummary ss ON ods.item_count >= ss.parts_count
)

SELECT 
    r.n_name AS nation_name,
    COUNT(DISTINCT rs.o_orderkey) AS order_count,
    AVG(rs.total_revenue) AS avg_revenue,
    MAX(rs.total_available_quantity) AS max_available_quantity,
    SUM(CASE WHEN rs.revenue_rank <= 5 THEN 1 ELSE 0 END) AS top_revenue_orders
FROM 
    RevenueStats rs
JOIN supplier s ON rs.s_suppkey = s.s_suppkey
JOIN nation r ON s.s_nationkey = r.n_nationkey
GROUP BY r.n_name
ORDER BY avg_revenue DESC
LIMIT 10;