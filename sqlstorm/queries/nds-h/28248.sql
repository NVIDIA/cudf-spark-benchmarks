WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_nationkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
)
SELECT 
    cs.c_name AS customer_name,
    ns.n_name AS nation_name,
    rs.s_name AS top_supplier,
    cs.total_spent,
    cs.order_count
FROM 
    CustomerSummary cs
JOIN 
    nation ns ON cs.c_nationkey = ns.n_nationkey
JOIN 
    RankedSuppliers rs ON cs.c_nationkey = rs.s_nationkey AND rs.rank = 1
WHERE 
    cs.total_spent > (SELECT AVG(total_spent) FROM CustomerSummary)
ORDER BY 
    cs.total_spent DESC;
