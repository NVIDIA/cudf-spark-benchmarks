
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '1 YEAR'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), HighRevenueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(lo.total_revenue) AS total_purchases
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        RankedOrders lo ON o.o_orderkey = lo.o_orderkey
    WHERE 
        lo.revenue_rank <= 10
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    rc.r_name AS region_name,
    nc.n_name AS nation_name,
    COUNT(DISTINCT hrc.c_custkey) AS high_value_customer_count,
    SUM(hrc.total_purchases) AS total_revenue_from_high_value_customers
FROM 
    region rc
JOIN 
    nation nc ON rc.r_regionkey = nc.n_regionkey
JOIN 
    supplier s ON nc.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    HighRevenueCustomers hrc ON hrc.total_purchases > 10000
GROUP BY 
    rc.r_name, nc.n_name
ORDER BY 
    total_revenue_from_high_value_customers DESC;
