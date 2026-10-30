
WITH TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > (
            SELECT AVG(total_cost)
            FROM (
                SELECT 
                    SUM(ps_supplycost * ps_availqty) AS total_cost
                FROM 
                    partsupp ps
                GROUP BY 
                    ps.ps_suppkey
            ) AS avg_costs
        )
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.r_name AS region_name, 
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(co.total_spent) AS total_spent_by_customers,
    COALESCE(MAX(ts.total_cost), 0) AS max_supplier_cost 
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    TopSuppliers ts ON s.s_suppkey = ts.s_suppkey
LEFT JOIN 
    CustomerOrders co ON s.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size > 10)
        LIMIT 1
    )
LEFT JOIN 
    customer c ON c.c_custkey = co.c_custkey
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 0
ORDER BY 
    total_spent_by_customers DESC;
