WITH RegionalStats AS (
    SELECT 
        r.r_name AS region_name,
        SUM(o.o_totalprice) AS total_revenue,
        COUNT(DISTINCT c.c_custkey) AS unique_customers,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        r.r_name
), OrderPriorities AS (
    SELECT 
        o.o_orderpriority,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderpriority
)
SELECT 
    rs.region_name,
    rs.total_revenue,
    rs.unique_customers,
    rs.total_orders,
    op.o_orderpriority,
    op.order_count
FROM 
    RegionalStats rs
JOIN 
    OrderPriorities op ON rs.total_orders > 0
ORDER BY 
    rs.total_revenue DESC, op.order_count DESC;