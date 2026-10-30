WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank_within_nation
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
QualifiedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        CASE 
            WHEN o.o_orderstatus = 'F' THEN 'Finalized'
            WHEN o.o_orderstatus = 'P' THEN 'Pending'
            ELSE 'Unknown Status'
        END AS order_status,
        o.o_orderdate,
        EXTRACT(YEAR FROM o.o_orderdate) AS order_year
    FROM 
        orders o
    WHERE 
        EXISTS (
            SELECT 1 
            FROM lineitem l 
            WHERE l.l_orderkey = o.o_orderkey 
            AND l.l_quantity > 100
        )
)
SELECT 
    q.order_year,
    COUNT(*) AS order_count,
    AVG(q.o_totalprice) AS average_order_value,
    SUM(COALESCE(l.l_quantity, 0)) AS total_line_items,
    r.s_name AS top_supplier_name,
    MAX(CASE WHEN l.l_discount > 0.2 THEN 1 ELSE 0 END) AS high_discount_flag
FROM 
    QualifiedOrders q
LEFT JOIN 
    lineitem l ON l.l_orderkey = q.o_orderkey
LEFT JOIN 
    RankedSuppliers r ON r.rank_within_nation = 1
GROUP BY 
    q.order_year, r.s_name
HAVING 
    AVG(q.o_totalprice) > 1000 OR COUNT(*) > 5
ORDER BY 
    q.order_year DESC, average_order_value DESC;
