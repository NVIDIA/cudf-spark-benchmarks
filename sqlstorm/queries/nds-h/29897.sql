
WITH  part_orders AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        p.p_name LIKE '%rubber%' AND
        o.o_orderdate >= '1997-01-01' AND
        o.o_orderdate < '1998-01-01'
    GROUP BY 
        p.p_partkey, p.p_name, s.s_name
    HAVING 
        SUM(l.l_quantity) > 500
)
SELECT 
    po.p_partkey,
    po.p_name,
    po.supplier_name,
    po.total_quantity,
    po.total_revenue,
    po.total_orders,
    RANK() OVER (ORDER BY po.total_revenue DESC) AS revenue_rank
FROM 
    part_orders po
ORDER BY 
    po.total_quantity DESC, po.total_revenue DESC;
