
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank,
        o.o_orderpriority,
        o.o_custkey
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate <= DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderpriority, o.o_custkey
),
TopRevenues AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        RANK() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(ro.revenue) DESC) AS nation_rank,
        SUM(ro.revenue) AS total_revenue
    FROM 
        RankedOrders ro
    JOIN 
        customer c ON ro.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name, n.n_name
)
SELECT 
    region_name,
    nation_name,
    total_revenue
FROM 
    TopRevenues
WHERE 
    nation_rank <= 5
ORDER BY 
    region_name, total_revenue DESC;
