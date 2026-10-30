WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey
)

SELECT 
    c.c_custkey, 
    c.c_name, 
    c.c_acctbal, 
    n.n_name AS nation,
    rs.s_name AS top_supplier,
    rs.total_supply_cost
FROM 
    customer c
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    RankedSuppliers rs ON n.n_nationkey = rs.s_nationkey 
WHERE 
    rs.rank = 1
AND 
    c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
ORDER BY 
    c.c_acctbal DESC
LIMIT 10;
