WITH SupplierAggregate AS (
    SELECT 
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_nationkey
),
CustomerRanking AS (
    SELECT 
        c.c_nationkey,
        c.c_name,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey, c.c_name
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT sa.supplier_count) AS unique_suppliers,
    SUM(sa.total_supplycost) AS total_supply_value,
    cr.c_name AS top_customer,
    cr.customer_rank
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    SupplierAggregate sa ON n.n_nationkey = sa.s_nationkey
LEFT JOIN 
    CustomerRanking cr ON n.n_nationkey = cr.c_nationkey AND cr.customer_rank = 1
GROUP BY 
    r.r_name, cr.c_name, cr.customer_rank
ORDER BY 
    total_supply_value DESC, unique_suppliers DESC;
