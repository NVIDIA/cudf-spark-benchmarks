WITH SupplierOrders AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
        AND l.l_returnflag = 'N'
    GROUP BY 
        s.s_suppkey, s.s_name
),
RankedSuppliers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        SupplierOrders
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COALESCE(r.total_quantity, 0) AS total_quantity,
        COALESCE(r.total_revenue, 0) AS total_revenue,
        r.order_count
    FROM 
        supplier s
    LEFT JOIN 
        RankedSuppliers r ON s.s_suppkey = r.s_suppkey
    WHERE 
        r.revenue_rank IS NULL OR r.total_revenue > 1000000
)
SELECT 
    h.s_name,
    h.total_quantity,
    h.total_revenue,
    h.order_count,
    CASE 
        WHEN h.total_revenue > 500000 THEN 'High'
        WHEN h.total_revenue BETWEEN 250000 AND 500000 THEN 'Medium'
        ELSE 'Low'
    END AS revenue_category,
    COUNT(DISTINCT l.l_partkey) AS distinct_parts_supplied
FROM 
    HighValueSuppliers h
LEFT JOIN 
    partsupp ps ON h.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
GROUP BY 
    h.s_name, h.total_quantity, h.total_revenue, h.order_count
ORDER BY 
    h.total_revenue DESC;