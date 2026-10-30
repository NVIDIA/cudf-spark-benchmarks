WITH SupplierOrders AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
NationSales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(so.total_sales) AS total_nation_sales
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        SupplierOrders so ON s.s_suppkey = so.s_suppkey
    GROUP BY 
        n.n_name
),
TopNations AS (
    SELECT 
        nation_name,
        total_nation_sales,
        RANK() OVER (ORDER BY total_nation_sales DESC) AS sales_rank
    FROM 
        NationSales
)
SELECT 
    tn.nation_name, 
    tn.total_nation_sales
FROM 
    TopNations tn
WHERE 
    tn.sales_rank <= 5
ORDER BY 
    tn.total_nation_sales DESC;
