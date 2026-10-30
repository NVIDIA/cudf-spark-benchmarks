WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= '1997-01-01'
        AND o.o_orderdate < '1998-01-01'
),
HighValueOrders AS (
    SELECT 
        r.r_name AS region,
        n.n_name AS nation,
        COUNT(ho.o_orderkey) AS order_count,
        SUM(ho.o_totalprice) AS total_revenue
    FROM 
        RankedOrders ho
    JOIN 
        customer c ON ho.c_name = c.c_name
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ho.rn <= 5
    GROUP BY 
        r.r_name, n.n_name
)
SELECT 
    hvo.region,
    hvo.nation,
    hvo.order_count,
    hvo.total_revenue,
    CASE 
        WHEN hvo.total_revenue > 1000000 THEN 'High Revenue'
        WHEN hvo.total_revenue BETWEEN 500000 AND 1000000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM 
    HighValueOrders hvo
ORDER BY 
    hvo.total_revenue DESC;