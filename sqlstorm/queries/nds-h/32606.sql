
WITH  top_suppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    ORDER BY 
        total_cost DESC
    LIMIT 5
),
popular_parts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        COUNT(l.l_orderkey) AS order_count
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        COUNT(l.l_orderkey) > (SELECT AVG(order_count) FROM (
            SELECT COUNT(l.l_orderkey) AS order_count 
            FROM part p
            JOIN lineitem l ON p.p_partkey = l.l_partkey
            GROUP BY p.p_partkey
        ) AS avg_orders)
),
supplier_performance AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        SUM(l.l_quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
)
SELECT 
    s.s_name,
    pp.p_name,
    sp.total_quantity,
    COALESCE(sp.revenue, 0) AS revenue
FROM 
    popular_parts pp
LEFT JOIN 
    supplier_performance sp ON pp.p_partkey IN (
        SELECT ps.ps_partkey 
        FROM partsupp ps 
        WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM top_suppliers s)
    )
JOIN 
    supplier s ON sp.s_suppkey = s.s_suppkey
WHERE 
    sp.rank <= 3 OR sp.revenue IS NULL
ORDER BY 
    sp.total_quantity DESC;
