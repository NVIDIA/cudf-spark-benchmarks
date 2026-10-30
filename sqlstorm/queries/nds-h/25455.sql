WITH SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT p.p_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        LENGTH(s.s_name) > 10
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        COUNT(DISTINCT p.p_partkey) > 5
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.part_count,
        p.total_cost,
        RANK() OVER (ORDER BY p.total_cost DESC) AS supplier_rank
    FROM 
        FilteredSuppliers p
    JOIN 
        supplier s ON p.s_suppkey = s.s_suppkey
)
SELECT 
    ts.supplier_rank,
    ts.s_name,
    ts.part_count,
    ts.total_cost
FROM 
    TopSuppliers ts
WHERE 
    ts.supplier_rank <= 10
ORDER BY 
    ts.total_cost DESC;
