
WITH ranked_sales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' 
        AND o.o_orderdate < '1998-01-01'
    GROUP BY 
        p.p_partkey, p.p_name
),
supplier_performance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT l.l_orderkey) AS order_count,
        AVG(l.l_extendedprice) AS avg_price
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
top_nations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(COALESCE(l.l_tax, 0)) AS total_taxes
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        n.n_name IS NOT NULL
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    r.r_name,
    COALESCE(r_sales.total_revenue, 0) AS total_revenue,
    COALESCE(s.order_count, 0) AS order_count,
    COALESCE(s.avg_price, 0) AS avg_price,
    COALESCE(t.total_taxes, 0) AS total_taxes
FROM 
    region r
LEFT JOIN 
    (SELECT p_partkey, total_revenue FROM ranked_sales WHERE rn = 1) r_sales ON r.r_regionkey = r_sales.p_partkey
LEFT JOIN 
    supplier_performance s ON r_sales.p_partkey = s.s_suppkey
LEFT JOIN 
    top_nations t ON r.r_regionkey = t.n_nationkey
ORDER BY 
    total_revenue DESC, 
    order_count DESC, 
    total_taxes DESC;
