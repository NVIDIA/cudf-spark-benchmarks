
WITH  SalesCTE AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
RankedSales AS (
    SELECT 
        o_orderkey, 
        o_orderdate, 
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesCTE
),
SupplierRevenue AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS supplier_total
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= '1996-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        supplier_total,
        RANK() OVER (ORDER BY supplier_total DESC) AS supplier_rank
    FROM 
        SupplierRevenue s
)
SELECT 
    ns.n_name AS nation_name,
    COALESCE(ts.s_name, 'Unknown Supplier') AS supplier_name,
    COUNT(DISTINCT os.o_orderkey) AS total_orders,
    SUM(r.total_sales) AS total_revenue,
    AVG(CASE WHEN ts.s_suppkey IS NOT NULL THEN ts.supplier_total ELSE 0 END) AS avg_supplier_revenue
FROM 
    nation ns
LEFT JOIN 
    customer c ON ns.n_nationkey = c.c_nationkey
LEFT JOIN 
    orders os ON c.c_custkey = os.o_custkey 
LEFT JOIN 
    RankedSales r ON r.o_orderkey = os.o_orderkey
LEFT JOIN 
    TopSuppliers ts ON r.total_sales = ts.supplier_total
WHERE 
    ns.n_name IS NOT NULL 
GROUP BY 
    ns.n_name, ts.s_name, ts.s_suppkey
HAVING 
    COUNT(DISTINCT os.o_orderkey) > 5
ORDER BY 
    total_revenue DESC;
