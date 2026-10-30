WITH OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, c.c_nationkey
),
RegionSales AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(od.total_revenue) AS region_total_revenue,
        COUNT(DISTINCT od.o_orderkey) AS total_orders
    FROM 
        OrderDetails od
    JOIN 
        customer c ON od.c_nationkey = c.c_nationkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_name, r.r_name
)
SELECT 
    region_name,
    nation_name,
    region_total_revenue,
    total_orders,
    RANK() OVER (ORDER BY region_total_revenue DESC) AS revenue_rank
FROM 
    RegionSales
ORDER BY 
    region_total_revenue DESC, nation_name;