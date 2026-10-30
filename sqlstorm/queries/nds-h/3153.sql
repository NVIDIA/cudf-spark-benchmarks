WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
),
TopSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.total_availqty,
        ss.avg_supplycost,
        RANK() OVER (ORDER BY ss.total_availqty DESC) AS supplier_rank
    FROM 
        SupplierStats ss
    WHERE 
        ss.total_availqty > 1000
)
SELECT 
    ts.s_suppkey,
    ts.s_name,
    ts.total_availqty,
    ts.avg_supplycost,
    os.o_orderkey,
    os.total_revenue,
    COALESCE(n.n_name, 'Unknown') AS nation_name
FROM 
    TopSuppliers ts
LEFT JOIN 
    orders o ON ts.s_suppkey = o.o_custkey
LEFT JOIN 
    OrderSummary os ON o.o_orderkey = os.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
WHERE 
    ts.supplier_rank <= 5 AND
    (os.total_revenue IS NOT NULL OR ts.avg_supplycost < 50)
ORDER BY 
    ts.total_availqty DESC, os.total_revenue DESC;
