WITH SupplierTotals AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_linenumber) AS line_count,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.r_name,
    COALESCE(SUM(st.total_cost), 0) AS total_supplier_cost,
    COALESCE(AVG(od.total_revenue), 0) AS avg_order_revenue,
    MAX(od.line_count) AS max_line_items
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierTotals st ON s.s_suppkey = st.s_suppkey
LEFT JOIN 
    OrderDetails od ON s.s_suppkey = od.o_orderkey
WHERE 
    (st.total_cost IS NOT NULL OR od.total_revenue IS NOT NULL)
    AND (r.r_name LIKE 'A%' OR r.r_name IS NULL)
GROUP BY 
    r.r_name
ORDER BY 
    total_supplier_cost DESC, avg_order_revenue ASC;
