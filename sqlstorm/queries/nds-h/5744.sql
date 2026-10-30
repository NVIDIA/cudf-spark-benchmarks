WITH SalesData AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        c.c_nationkey,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, c.c_nationkey, n.n_name, r.r_name, o.o_orderdate
),
RankedSales AS (
    SELECT 
        *,
        DENSE_RANK() OVER (PARTITION BY nation_name ORDER BY revenue DESC) AS revenue_rank
    FROM 
        SalesData
)
SELECT 
    nation_name,
    region_name,
    revenue,
    o_orderkey,
    o_orderdate
FROM 
    RankedSales
WHERE 
    revenue_rank <= 10
ORDER BY 
    region_name, revenue DESC;
