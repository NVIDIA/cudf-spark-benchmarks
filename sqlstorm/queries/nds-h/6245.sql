WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O'
),
RecentOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_name
    FROM 
        RankedOrders ro
    WHERE 
        ro.rn = 1
),
PartRevenue AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        RecentOrders ro ON l.l_orderkey = ro.o_orderkey
    GROUP BY 
        l.l_partkey
),
TopParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        pr.total_revenue,
        RANK() OVER (ORDER BY pr.total_revenue DESC) AS part_rank
    FROM 
        part p
    JOIN 
        PartRevenue pr ON p.p_partkey = pr.l_partkey
)
SELECT 
    tp.p_partkey,
    tp.p_name,
    tp.total_revenue,
    CASE 
        WHEN tp.part_rank <= 10 THEN 'Top 10'
        ELSE 'Others'
    END AS revenue_category
FROM 
    TopParts tp
ORDER BY 
    tp.total_revenue DESC;
