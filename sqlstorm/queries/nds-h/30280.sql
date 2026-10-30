
WITH  sales_summary AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS spend_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
    GROUP BY 
        c.c_custkey, c.c_nationkey
), 
supplier_cost AS (
    SELECT 
        ps.ps_partkey,
        s.s_nationkey,
        AVG(ps.ps_supplycost) AS avg_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_nationkey
),
part_usage AS (
    SELECT 
        p.p_partkey,
        COUNT(DISTINCT l.l_orderkey) AS order_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        part p
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey
)
SELECT 
    r.r_name,
    COALESCE(s.total_spent, 0) AS total_sales,
    COALESCE(pc.order_count, 0) AS orders_count,
    COALESCE(pc.total_revenue, 0.00) AS total_revenue,
    sc.avg_cost
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    sales_summary s ON n.n_nationkey = s.c_custkey
LEFT JOIN 
    supplier_cost sc ON n.n_nationkey = sc.s_nationkey
LEFT JOIN 
    part_usage pc ON sc.ps_partkey = pc.p_partkey
WHERE 
    r.r_name LIKE '%South%' OR r.r_name IS NULL
ORDER BY 
    total_sales DESC, total_revenue DESC;
