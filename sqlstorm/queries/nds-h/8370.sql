WITH RankedSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        c.c_custkey, c.c_name, n.n_nationkey
),
TopSales AS (
    SELECT 
        n.n_name,
        r.r_name,
        SUM(rs.total_sales) AS total_sales
    FROM 
        RankedSales rs
    JOIN 
        customer c ON rs.c_custkey = c.c_custkey
    JOIN 
        supplier s ON c.c_nationkey = s.s_nationkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.sales_rank <= 10
    GROUP BY 
        n.n_name, r.r_name
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    SUM(ts.total_sales) AS total_sales
FROM 
    TopSales ts
JOIN 
    region r ON ts.r_name = r.r_name
JOIN 
    nation n ON ts.n_name = n.n_name
GROUP BY 
    r.r_name, n.n_name
ORDER BY 
    r.r_name, total_sales DESC;