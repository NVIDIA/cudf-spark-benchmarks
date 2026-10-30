WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1997-02-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name, s.s_name
),
FilteredRevenue AS (
    SELECT 
        r.* 
    FROM 
        RankedOrders r
    WHERE 
        r.revenue_rank = 1
)
SELECT 
    f.o_orderkey,
    f.o_orderdate,
    f.c_name AS customer_name,
    f.s_name AS supplier_name,
    f.total_revenue
FROM 
    FilteredRevenue f
ORDER BY 
    f.total_revenue DESC
LIMIT 10;