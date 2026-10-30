WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_nationkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent,
        ROW_NUMBER() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    ns.n_name AS nation_name,
    COUNT(DISTINCT hs.c_custkey) AS high_value_customer_count,
    SUM(rs.total_supply_cost) AS total_supply_cost_by_nation
FROM 
    nation ns
LEFT JOIN 
    RankedSuppliers rs ON ns.n_nationkey = rs.s_suppkey
LEFT JOIN 
    HighValueCustomers hs ON hs.customer_rank <= 10
WHERE 
    rs.supplier_rank <= 5
GROUP BY 
    ns.n_name
ORDER BY 
    total_supply_cost_by_nation DESC, high_value_customer_count DESC;
