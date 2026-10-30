WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts,
        SUM(CASE WHEN l.l_shipdate >= cast('1998-10-01' as date) - INTERVAL '1 year' THEN l.l_quantity ELSE 0 END) AS recent_quantity
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        ss.total_supplycost, 
        ss.unique_parts, 
        ss.recent_quantity,
        RANK() OVER (ORDER BY ss.total_supplycost DESC) AS rank
    FROM 
        supplier s
    JOIN 
        SupplierSummary ss ON s.s_suppkey = ss.s_suppkey
)
SELECT 
    t.s_suppkey, 
    t.s_name, 
    t.total_supplycost, 
    t.unique_parts, 
    t.recent_quantity
FROM 
    TopSuppliers t
WHERE 
    t.rank <= 10
ORDER BY 
    t.total_supplycost DESC;