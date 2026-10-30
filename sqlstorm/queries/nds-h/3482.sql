WITH Supplier_Sales AS (
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
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1997-10-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),

Top_Suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_sales,
        ss.order_count,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        Supplier_Sales ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
)

SELECT 
    ts.s_suppkey,
    ts.s_name,
    ts.total_sales,
    ts.order_count,
    COALESCE(n.n_name, 'Unknown') AS supplier_nation,
    CASE 
        WHEN ts.sales_rank <= 5 THEN 'Top 5 Supplier'
        ELSE 'Below Top 5'
    END AS supplier_status
FROM 
    Top_Suppliers ts
LEFT JOIN 
    supplier s ON ts.s_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    ts.order_count > 10
ORDER BY 
    ts.total_sales DESC;