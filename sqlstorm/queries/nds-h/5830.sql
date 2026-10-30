
WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(o.o_totalprice) AS total_sales
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        r.r_name
), CustomerSpend AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spend
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), HighSpenders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        cs.total_spend
    FROM 
        CustomerSpend cs
    JOIN 
        customer c ON cs.c_custkey = c.c_custkey
    WHERE 
        cs.total_spend > (SELECT AVG(total_spend) FROM CustomerSpend)
), TopRegions AS (
    SELECT 
        rs.region_name,
        rs.total_sales,
        RANK() OVER (ORDER BY rs.total_sales DESC) AS sales_rank
    FROM 
        RegionalSales rs
)

SELECT 
    hr.c_name,
    tr.region_name,
    tr.total_sales,
    hr.total_spend
FROM 
    HighSpenders hr
JOIN 
    TopRegions tr ON tr.sales_rank <= 5
ORDER BY 
    hr.total_spend DESC, tr.total_sales DESC;
