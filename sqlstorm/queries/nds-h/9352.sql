WITH supplier_totals AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
customer_order_totals AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
lineitem_summary AS (
    SELECT 
        l.l_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        SUM(l.l_quantity) AS total_quantity,
        AVG(l.l_discount) AS avg_discount
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1998-01-01'
    GROUP BY 
        l.l_suppkey
)
SELECT 
    n.n_name AS nation,
    r.r_name AS region,
    s.s_name AS supplier_name,
    COALESCE(st.total_supply_value, 0) AS total_supply_value,
    COALESCE(ct.total_order_value, 0) AS total_order_value,
    COALESCE(ls.revenue, 0) AS total_revenue,
    COALESCE(ls.total_quantity, 0) AS total_quantity,
    ls.avg_discount AS average_discount
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    supplier_totals st ON s.s_suppkey = st.s_suppkey
LEFT JOIN 
    customer_order_totals ct ON s.s_suppkey = ct.c_custkey
LEFT JOIN 
    lineitem_summary ls ON s.s_suppkey = ls.l_suppkey
ORDER BY 
    total_revenue DESC, 
    total_supply_value DESC;