
WITH CustomerPriority AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_acctbal, 
        SUM(o.o_totalprice) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rn
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal, c.c_nationkey
),
SupplierPerformance AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
NationSummary AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        COUNT(DISTINCT c.c_custkey) AS num_customers,
        COUNT(DISTINCT s.s_suppkey) AS num_suppliers
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    cp.c_name,
    cp.total_spent,
    sp.total_supply_value,
    ns.num_customers,
    ns.num_suppliers
FROM 
    CustomerPriority cp
JOIN 
    SupplierPerformance sp ON sp.total_supply_value IS NOT NULL
JOIN 
    NationSummary ns ON ns.num_customers > 0
WHERE 
    cp.rn <= 5 AND 
    cp.total_spent > (SELECT AVG(total_spent) FROM CustomerPriority) 
ORDER BY 
    cp.total_spent DESC, 
    sp.total_supply_value DESC;
