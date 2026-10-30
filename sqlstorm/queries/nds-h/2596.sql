WITH OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopOrders AS (
    SELECT 
        od.o_orderkey,
        od.o_orderdate,
        od.total_revenue,
        od.unique_parts,
        RANK() OVER (ORDER BY od.total_revenue DESC) AS revenue_rank
    FROM 
        OrderDetails od
)
SELECT 
    t.o_orderkey,
    t.o_orderdate,
    t.total_revenue,
    t.unique_parts,
    COALESCE(p.p_name, 'Unknown Part') AS top_part_name,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    CASE 
        WHEN t.unique_parts > 10 THEN 'High Variety'
        WHEN t.unique_parts BETWEEN 5 AND 10 THEN 'Medium Variety'
        ELSE 'Low Variety'
    END AS variety_category
FROM 
    TopOrders t
LEFT JOIN 
    lineitem l ON t.o_orderkey = l.l_orderkey
LEFT JOIN 
    part p ON l.l_partkey = p.p_partkey
LEFT JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
WHERE 
    t.revenue_rank <= 10
ORDER BY 
    t.total_revenue DESC, t.o_orderdate ASC;