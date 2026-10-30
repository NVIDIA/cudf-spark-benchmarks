WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey,
        s.s_name,
        n.n_name
),
RankedSales AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.nation_name,
        ss.total_sales,
        ss.total_orders,
        RANK() OVER (PARTITION BY ss.nation_name ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        SupplierSales ss
)
SELECT 
    r.nation_name,
    r.s_suppkey,
    r.s_name,
    r.total_sales,
    r.total_orders,
    r.sales_rank
FROM 
    RankedSales r
WHERE 
    r.sales_rank <= 5
ORDER BY 
    r.nation_name,
    r.total_sales DESC;
