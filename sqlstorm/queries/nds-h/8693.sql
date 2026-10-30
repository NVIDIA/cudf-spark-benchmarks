WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * l.l_quantity) AS total_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        st.nation_name,
        st.total_sales,
        RANK() OVER (PARTITION BY st.nation_name ORDER BY st.total_sales DESC) AS sales_rank
    FROM 
        SupplierSales st
    JOIN 
        supplier s ON s.s_suppkey = st.s_suppkey
),
FinalReport AS (
    SELECT 
        ts.nation_name,
        ts.s_name,
        ts.total_sales,
        ts.sales_rank
    FROM 
        TopSuppliers ts
    WHERE 
        ts.sales_rank <= 5
)
SELECT 
    nation_name,
    COUNT(DISTINCT s_name) AS supplier_count,
    SUM(total_sales) AS total_sales_amount
FROM 
    FinalReport
GROUP BY 
    nation_name
ORDER BY 
    total_sales_amount DESC;