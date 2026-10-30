
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supplycost,
        AVG(ps.ps_availqty) AS avg_avail_qty
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM 
        orders o
    INNER JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01'  -- Removed DATE keyword for compatibility
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.part_count,
        ss.total_supplycost,
        ss.avg_avail_qty,
        RANK() OVER (ORDER BY ss.total_supplycost DESC) AS supplier_rank
    FROM 
        SupplierStats ss
    WHERE 
        ss.part_count > 10
)
SELECT 
    os.o_orderkey,
    os.o_orderdate,
    os.total_revenue,
    os.distinct_parts,
    ts.s_name AS top_supplier_name,
    ts.total_supplycost,
    CASE 
        WHEN os.total_revenue > 10000 THEN 'High Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM 
    OrderSummary os
LEFT JOIN 
    TopSuppliers ts ON os.o_orderkey = ts.s_suppkey -- Fixed join condition
WHERE 
    ts.supplier_rank IS NOT NULL -- Fixed column name
ORDER BY 
    os.total_revenue DESC; -- Removed NULLS LAST for compatibility
