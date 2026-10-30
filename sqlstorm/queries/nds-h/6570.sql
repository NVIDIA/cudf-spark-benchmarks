WITH  sales_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_sales,
        COUNT(o.o_orderkey) AS order_count,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > (
            SELECT AVG(c2.c_acctbal) 
            FROM customer c2 
            WHERE c2.c_mktsegment = c.c_mktsegment
        )
    GROUP BY 
        c.c_custkey, c.c_name
),
high_value_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > 10000
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 200000
),
top_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1997-12-31'
    GROUP BY 
        p.p_partkey, p.p_name
    ORDER BY 
        revenue DESC
    LIMIT 10
)
SELECT 
    s.s_name AS supplier_name,
    ss.c_name AS customer_name,
    tp.p_name AS top_part_name,
    tp.revenue AS part_revenue
FROM 
    high_value_suppliers s
JOIN 
    sales_summary ss ON ss.total_sales > 10000
JOIN 
    top_parts tp ON tp.revenue > 5000
ORDER BY 
    s.s_name, ss.sales_rank;