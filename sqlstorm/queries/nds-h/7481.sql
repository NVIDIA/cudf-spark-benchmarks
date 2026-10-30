
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        c.c_acctbal,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, c.c_name, c.c_acctbal, c.c_nationkey
),
TopCustomers AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        rc.c_name AS customer_name,
        rc.total_revenue
    FROM 
        RankedOrders rc
    JOIN 
        supplier s ON rc.o_orderkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rc.revenue_rank <= 5
)
SELECT 
    region_name,
    nation_name,
    COUNT(DISTINCT customer_name) AS top_customer_count,
    SUM(total_revenue) AS total_revenue_sum
FROM 
    TopCustomers
GROUP BY 
    region_name, nation_name
ORDER BY 
    region_name, nation_name;
