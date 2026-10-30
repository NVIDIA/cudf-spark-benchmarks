WITH total_revenue AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        c.c_custkey
),
ranked_revenue AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        r.revenue,
        RANK() OVER (ORDER BY r.revenue DESC) AS revenue_rank
    FROM 
        total_revenue r
    JOIN 
        customer c ON r.c_custkey = c.c_custkey
),
top_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        r.revenue
    FROM 
        ranked_revenue r
    JOIN 
        customer c ON r.c_custkey = c.c_custkey
    WHERE 
        r.revenue_rank <= 10
),
supplier_part_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey, p.p_name
)
SELECT 
    tc.c_custkey,
    tc.c_name,
    spi.s_suppkey,
    spi.s_name,
    spi.p_partkey,
    spi.p_name,
    spi.total_available
FROM 
    top_customers tc
JOIN 
    lineitem l ON tc.c_custkey = l.l_orderkey
JOIN 
    supplier_part_info spi ON l.l_suppkey = spi.s_suppkey
WHERE 
    l.l_shipdate >= DATE '1996-01-01' AND l.l_shipdate < DATE '1997-01-01'
ORDER BY 
    tc.revenue DESC, spi.total_available DESC;