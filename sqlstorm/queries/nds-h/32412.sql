
WITH  RegionSales AS (
    SELECT 
        r.r_regionkey, 
        r.r_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
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
    GROUP BY 
        r.r_regionkey, r.r_name
), 
TotalSales AS (
    SELECT 
        SUM(total_sales) AS overall_sales 
    FROM 
        RegionSales
),
CustomerSales AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS customer_total
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
),
RankedCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        cs.customer_total, 
        RANK() OVER (ORDER BY cs.customer_total DESC) AS rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_custkey = c.c_custkey
)
SELECT 
    rs.r_name,
    COUNT(DISTINCT rc.c_custkey) AS customer_count,
    COALESCE(SUM(rc.customer_total), 0) AS total_customer_sales,
    (
        SELECT 
            COUNT(*)
        FROM 
            RankedCustomers r 
        WHERE 
            r.rank <= 10
    ) AS top_customers_count,
    ts.overall_sales
FROM 
    RegionSales rs
CROSS JOIN 
    TotalSales ts
LEFT JOIN 
    RankedCustomers rc ON rc.customer_total > 1000
GROUP BY 
    rs.r_name, ts.overall_sales
HAVING 
    COALESCE(SUM(rc.customer_total), 0) > (SELECT overall_sales / 10 FROM TotalSales)
ORDER BY 
    total_customer_sales DESC;
