WITH  RegionalSales (r_regionkey, r_name, total_sales, rank_position) AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_position
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= DATE '1996-01-01' AND l.l_shipdate < DATE '1997-01-01'
    GROUP BY 
        r.r_regionkey, r.r_name
),
TopRegions AS (
    SELECT 
        r_regionkey, 
        r_name, 
        total_sales,
        rank_position
    FROM 
        RegionalSales 
    WHERE 
        rank_position <= 3
),
CustomerSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_customer_sales
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    tr.r_name AS region_name,
    tr.total_sales AS region_sales,
    cs.c_name AS customer_name,
    cs.total_customer_sales AS customer_sales
FROM 
    TopRegions tr
FULL OUTER JOIN 
    CustomerSales cs ON tr.r_regionkey = cs.c_custkey
WHERE 
    (tr.total_sales IS NOT NULL AND cs.total_customer_sales IS NOT NULL)
    OR (tr.total_sales IS NULL AND cs.total_customer_sales IS NOT NULL)
ORDER BY 
    tr.total_sales DESC NULLS LAST, cs.total_customer_sales DESC NULLS LAST;