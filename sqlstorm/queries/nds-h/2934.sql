WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 50000
),
PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    ps.p_partkey,
    ps.p_name,
    ps.total_available,
    ps.avg_supply_cost,
    COALESCE(r.s_name, 'No Supplier') AS supplier_name,
    COALESCE(hc.c_name, 'No High-Value Customer') AS customer_name,
    CASE 
        WHEN ps.avg_supply_cost > 100 THEN 'Expensive'
        WHEN ps.avg_supply_cost BETWEEN 50 AND 100 THEN 'Moderate'
        ELSE 'Cheap'
    END AS cost_category
FROM 
    PartSupplierDetails ps
LEFT JOIN 
    RankedSuppliers r ON ps.p_partkey = r.s_suppkey AND r.rnk = 1
LEFT JOIN 
    HighValueCustomers hc ON r.s_suppkey = hc.c_custkey
WHERE 
    ps.total_available < (SELECT AVG(total_available) FROM PartSupplierDetails)
ORDER BY 
    ps.p_partkey;
