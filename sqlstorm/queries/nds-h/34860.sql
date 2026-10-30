WITH  sales_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(*) AS total_items,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o 
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_custkey
),
supplier_sales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
distinct_parts AS (
    SELECT 
        DISTINCT p.p_partkey,
        p.p_name,
        p.p_retailprice
    FROM 
        part p
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate IS NOT NULL
)
SELECT 
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(ss.total_sales) AS total_revenue,
    COALESCE(SUM(ss.total_items), 0) AS total_items_sold,
    COALESCE(MAX(ss.total_sales), 0) AS max_sales_per_order,
    ds.p_name,
    ds.p_retailprice
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    sales_summary ss ON c.c_custkey = ss.o_orderkey
LEFT JOIN 
    distinct_parts ds ON ss.o_orderkey = ds.p_partkey
GROUP BY 
    r.r_name, ds.p_name, ds.p_retailprice
HAVING 
    SUM(ss.total_sales) > 100000
ORDER BY 
    total_revenue DESC;