WITH RegionSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(lp.l_extendedprice * (1 - lp.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
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
        lineitem lp ON p.p_partkey = lp.l_partkey
    JOIN 
        orders o ON lp.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND 
        o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        r.r_name
),
CustomerRank AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(lp.l_extendedprice * (1 - lp.l_discount)) AS customer_total_sales,
        RANK() OVER (ORDER BY SUM(lp.l_extendedprice * (1 - lp.l_discount)) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem lp ON o.o_orderkey = lp.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND 
        o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    rs.region_name,
    rs.total_sales,
    COALESCE(cr.customer_total_sales, 0) AS top_customer_sales,
    cr.c_name AS top_customer_name
FROM 
    RegionSales rs
LEFT JOIN 
    (SELECT * FROM CustomerRank WHERE sales_rank = 1) cr ON rs.total_sales = cr.customer_total_sales
ORDER BY 
    rs.total_sales DESC;