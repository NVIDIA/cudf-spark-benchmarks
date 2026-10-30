WITH RankedSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
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
    GROUP BY 
        c.c_custkey, c.c_name, n.n_nationkey
),
TopCustomers AS (
    SELECT 
        n.n_name AS nation,
        r.r_name AS region,
        r.r_comment,
        c.c_custkey,
        c.c_name,
        rs.total_revenue
    FROM 
        RankedSales rs
    JOIN 
        customer c ON c.c_custkey = rs.c_custkey
    JOIN 
        supplier s ON s.s_nationkey = c.c_nationkey
    JOIN 
        nation n ON n.n_nationkey = s.s_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.revenue_rank <= 5
)
SELECT 
    nation, 
    region, 
    COUNT(c_custkey) AS top_customer_count, 
    SUM(total_revenue) AS total_revenue_from_top_customers
FROM 
    TopCustomers
GROUP BY 
    nation, region
ORDER BY 
    total_revenue_from_top_customers DESC;
