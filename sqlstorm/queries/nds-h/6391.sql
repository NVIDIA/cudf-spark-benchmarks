WITH OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_suppkey) AS supplier_count,
        MAX(o.o_orderdate) AS latest_order_date
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey
),
TopOrders AS (
    SELECT 
        od.o_orderkey,
        od.total_revenue,
        od.supplier_count,
        RANK() OVER (ORDER BY od.total_revenue DESC) AS revenue_rank
    FROM 
        OrderDetails od
)
SELECT 
    t.o_orderkey,
    t.total_revenue,
    t.supplier_count,
    t.revenue_rank,
    c.c_name AS customer_name,
    s.s_name AS supplier_name,
    p.p_name AS part_name
FROM 
    TopOrders t
JOIN 
    orders o ON t.o_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
WHERE 
    t.revenue_rank <= 10
ORDER BY 
    t.total_revenue DESC;