WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        n.n_name AS nation,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
),
TopNations AS (
    SELECT 
        n.n_name, 
        SUM(o.o_totalprice) AS total_revenue
    FROM 
        RankedOrders o
    JOIN 
        nation n ON o.nation = n.n_name
    GROUP BY 
        n.n_name
    ORDER BY 
        total_revenue DESC
    LIMIT 5
)
SELECT 
    p.p_brand,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(o.o_totalprice) AS avg_order_value
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    RankedOrders r ON o.o_orderkey = r.o_orderkey
WHERE 
    r.rank <= 5 AND 
    p.p_type LIKE '%rubber%'
GROUP BY 
    p.p_brand
ORDER BY 
    total_sales DESC;