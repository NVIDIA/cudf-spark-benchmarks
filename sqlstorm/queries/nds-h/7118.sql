WITH Revenue AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1997-12-31'
    GROUP BY 
        l.l_orderkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        r.r_name AS region_name,
        n.n_name AS nation_name,
        c.c_mktsegment
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    od.o_orderkey,
    od.o_orderstatus,
    od.o_totalprice,
    od.o_orderdate,
    od.region_name,
    od.nation_name,
    od.c_mktsegment,
    COALESCE(r.total_revenue, 0) AS revenue
FROM 
    OrderDetails od
LEFT JOIN 
    Revenue r ON od.o_orderkey = r.l_orderkey
WHERE 
    od.o_totalprice > 1000
ORDER BY 
    revenue DESC, od.o_orderdate DESC
LIMIT 100;