WITH SupplierSales AS (
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
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sales.total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        supplier s
    JOIN 
        SupplierSales sales ON s.s_suppkey = sales.s_suppkey
),
NationStats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        AVG(s.s_acctbal) AS avg_account_balance
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)

SELECT 
    ts.s_name,
    ts.total_sales,
    ns.n_name,
    ns.supplier_count,
    ns.avg_account_balance
FROM 
    TopSuppliers ts
JOIN 
    supplier s ON ts.s_suppkey = s.s_suppkey
LEFT JOIN 
    NationStats ns ON s.s_nationkey = ns.n_nationkey
WHERE 
    ts.sales_rank <= 10 
    AND (ns.avg_account_balance IS NULL OR ns.avg_account_balance > 5000)
ORDER BY 
    ts.total_sales DESC;