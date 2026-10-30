WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
CustomerRevenue AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(RO.total_revenue) AS total_customer_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        RankedOrders RO ON o.o_orderkey = RO.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    cr.c_custkey,
    cr.c_name,
    cr.total_customer_revenue,
    rn.r_regionkey,
    r.r_name AS region_name
FROM 
    CustomerRevenue cr
JOIN 
    supplier s ON cr.total_customer_revenue > s.s_acctbal
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    (SELECT 
         DISTINCT r_regionkey 
     FROM 
         region
     WHERE 
         r_comment LIKE '%important%') rn ON r.r_regionkey = rn.r_regionkey
WHERE 
    cr.total_customer_revenue > 10000
ORDER BY 
    cr.total_customer_revenue DESC;
