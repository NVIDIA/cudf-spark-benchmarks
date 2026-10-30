WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS ranking
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        SUM(o.o_totalprice) AS total_orders,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PopularParts AS (
    SELECT 
        l.l_partkey,
        p.p_name,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        lineitem l
    JOIN 
        part p ON l.l_partkey = p.p_partkey
    GROUP BY 
        l.l_partkey, p.p_name
    HAVING 
        SUM(l.l_quantity) > 100 
)
SELECT 
    cs.c_name,
    cs.total_orders,
    COALESCE(rs.s_name, 'No Supplier') AS primary_supplier,
    pp.p_name AS popular_part,
    pp.total_quantity
FROM 
    CustomerOrderStats cs
LEFT JOIN 
    RankedSuppliers rs ON cs.c_custkey = rs.s_suppkey
LEFT JOIN 
    PopularParts pp ON pp.l_partkey = rs.s_suppkey
WHERE 
    cs.order_count > 0 
    AND rs.ranking = 1
ORDER BY 
    cs.total_orders DESC, 
    pp.total_quantity DESC;
