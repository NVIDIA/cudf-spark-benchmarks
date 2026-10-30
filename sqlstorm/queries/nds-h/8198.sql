WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.total_cost,
        RANK() OVER (ORDER BY rs.total_cost DESC) AS supplier_rank
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.total_cost > 10000
),
NationSummary AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(o.o_totalprice) AS total_sales
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_name
)
SELECT 
    ns.n_name,
    ns.customer_count,
    ns.total_sales,
    ts.s_name AS top_supplier,
    ts.total_cost AS top_supplier_cost
FROM 
    NationSummary ns
LEFT JOIN 
    TopSuppliers ts ON ns.customer_count > 10
WHERE 
    ns.total_sales > 50000
ORDER BY 
    ns.total_sales DESC, ns.n_name;
