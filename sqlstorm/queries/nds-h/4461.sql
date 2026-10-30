
WITH RankedSuppliers AS (
    SELECT 
        ps.ps_partkey,
        s.s_nationkey,
        s.s_suppkey,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS rn
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        ps.ps_availqty > 0
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
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 5000
),
SupplierParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    r.n_name AS nation_name,
    sp.supplier_count,
    hvc.total_spent,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
    CASE 
        WHEN r.n_name IS NULL THEN 'Unknown Nation'
        ELSE r.n_name
    END AS adjusted_nation_name
FROM 
    nation r
LEFT JOIN 
    RankedSuppliers rs ON rs.s_nationkey = r.n_nationkey 
LEFT JOIN 
    SupplierParts sp ON sp.p_partkey = rs.ps_partkey
LEFT JOIN 
    lineitem l ON l.l_suppkey = rs.s_suppkey 
LEFT JOIN 
    HighValueCustomers hvc ON hvc.c_custkey = l.l_orderkey
WHERE 
    (sp.supplier_count > 1 OR sp.supplier_count IS NULL)
GROUP BY 
    r.n_name, sp.supplier_count, hvc.total_spent
ORDER BY 
    adjusted_nation_name DESC;
