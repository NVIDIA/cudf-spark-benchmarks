WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(CASE WHEN rs.rank <= 3 THEN rs.total_cost ELSE 0 END) AS top_suppliers_cost
    FROM 
        nation n
    JOIN 
        RankedSuppliers rs ON n.n_nationkey = rs.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    n.n_name,
    n.top_suppliers_cost,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    AVG(o.o_totalprice) AS avg_order_value
FROM 
    TopNations n
JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
JOIN 
    orders o ON o.o_custkey = c.c_custkey
WHERE 
    n.top_suppliers_cost > 100000
GROUP BY 
    n.n_name, n.top_suppliers_cost
ORDER BY 
    n.top_suppliers_cost DESC;
