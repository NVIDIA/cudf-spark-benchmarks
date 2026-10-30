WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey
),
CustomerOrderData AS (
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
    n.n_name,
    r.r_name,
    COALESCE(cod.order_count, 0) AS total_orders,
    COALESCE(cod.total_spent, 0) AS total_spent,
    rs.s_name AS top_supplier,
    rs.total_cost
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    CustomerOrderData cod ON n.n_nationkey = cod.c_custkey
LEFT JOIN 
    RankedSuppliers rs ON rs.supplier_rank = 1
WHERE 
    n.n_name LIKE '%land%'
  AND 
    (cod.total_spent > (SELECT AVG(total_spent) FROM CustomerOrderData) OR rs.total_cost IS NOT NULL)
ORDER BY 
    n.n_name ASC, 
    total_orders DESC;
