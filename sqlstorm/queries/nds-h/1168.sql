WITH SuppOrderSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s_suppkey, 
        s_name, 
        total_sales,
        order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SuppOrderSummary
)
SELECT 
    r.r_name AS region_name,
    ns.n_name AS nation_name,
    COUNT(DISTINCT ts.s_suppkey) AS supplier_count,
    SUM(ts.total_sales) AS total_sales_value
FROM 
    TopSuppliers ts
LEFT JOIN 
    supplier s ON ts.s_suppkey = s.s_suppkey
LEFT JOIN 
    nation ns ON s.s_nationkey = ns.n_nationkey
JOIN 
    region r ON ns.n_regionkey = r.r_regionkey
WHERE 
    ts.sales_rank <= 10 AND 
    (r.r_name IS NOT NULL OR ns.n_name IS NOT NULL)
GROUP BY 
    r.r_name, ns.n_name
ORDER BY 
    total_sales_value DESC;
