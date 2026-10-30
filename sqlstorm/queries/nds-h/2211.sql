
WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS num_parts,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS num_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey
),
QualifiedSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name
    FROM 
        SupplierSummary ss
    WHERE 
        ss.total_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierSummary)
)
SELECT 
    cs.c_custkey,
    cs.num_orders,
    cs.total_spent,
    qs.s_name AS supplier_name
FROM 
    CustomerOrderSummary cs
LEFT JOIN 
    lineitem li ON cs.c_custkey = li.l_orderkey
LEFT JOIN 
    QualifiedSuppliers qs ON li.l_suppkey = qs.s_suppkey
WHERE 
    cs.total_spent > 1000
    AND (qs.s_name IS NOT NULL OR cs.num_orders IS NULL)
ORDER BY 
    cs.total_spent DESC;
