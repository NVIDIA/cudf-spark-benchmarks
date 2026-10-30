
WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
),
supplier_order_details AS (
    SELECT 
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_name
),
high_value_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        s.s_name
    FROM 
        ranked_orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    LEFT JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        o.rank <= 10
),
aggregated_data AS (
    SELECT 
        sd.s_name,
        COALESCE(SUM(h.o_totalprice), 0) AS order_total,
        COALESCE(SUM(h.o_totalprice) / NULLIF(COUNT(h.o_orderkey), 0), 0) AS avg_order_value
    FROM 
        supplier_order_details sd
    LEFT JOIN 
        high_value_orders h ON sd.s_name = h.s_name
    GROUP BY 
        sd.s_name
)
SELECT 
    a.s_name,
    a.order_total,
    a.avg_order_value,
    CASE 
        WHEN a.order_total > 10000 THEN 'High Value Supplier'
        WHEN a.order_total BETWEEN 5000 AND 10000 THEN 'Medium Value Supplier'
        ELSE 'Low Value Supplier'
    END AS supplier_category
FROM 
    aggregated_data a
WHERE 
    a.order_total > 0
ORDER BY 
    a.order_total DESC;
