WITH  regional_sales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        n.n_name
),
high_value_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(DISTINCT l.l_linenumber) AS item_count
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
),
overall_summary AS (
    SELECT 
        r.nation_name,
        h.total_order_value,
        COUNT(DISTINCT h.o_orderkey) AS order_count,
        AVG(h.total_order_value) AS avg_order_value
    FROM 
        regional_sales r
    LEFT JOIN 
        high_value_orders h ON r.nation_name = h.c_name
    GROUP BY 
        r.nation_name, h.total_order_value
)
SELECT 
    o.nation_name,
    COALESCE(SUM(o.total_order_value), 0) AS total_order_value,
    COALESCE(SUM(o.order_count), 0) AS total_order_count,
    COALESCE(AVG(o.avg_order_value), 0) AS avg_value_per_order
FROM 
    overall_summary o
GROUP BY 
    o.nation_name
ORDER BY 
    total_order_value DESC 
LIMIT 10;