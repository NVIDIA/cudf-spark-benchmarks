WITH RankedSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
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
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSupp AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        s.s_name AS supplier_name,
        rs.total_sales
    FROM 
        RankedSales rs
    JOIN 
        supplier s ON rs.s_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.sales_rank <= 3
),
CustomerSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS customer_sales
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    ts.region_name,
    ts.nation_name,
    ts.supplier_name,
    ts.total_sales,
    cs.c_name AS top_customer,
    cs.customer_sales
FROM 
    TopSupp ts
LEFT JOIN 
    (SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS customer_sales,
        RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS cust_rank
     FROM 
        customer c
     JOIN 
        orders o ON c.c_custkey = o.o_custkey
     JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
     GROUP BY 
        c.c_custkey, c.c_name
    ) cs ON cs.cust_rank = 1
WHERE 
    ts.total_sales IS NOT NULL
ORDER BY 
    ts.region_name, ts.nation_name, ts.total_sales DESC;
