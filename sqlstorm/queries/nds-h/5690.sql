
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        s.s_name AS supplier_name,
        ROW_NUMBER() OVER(PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
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
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
),
FinalSummary AS (
    SELECT 
        COUNT(DISTINCT o_orderkey) AS total_orders,
        SUM(o_totalprice) AS total_revenue,
        AVG(o_totalprice) AS average_order_value,
        MIN(o_orderdate) AS first_order_date,
        MAX(o_orderdate) AS last_order_date
    FROM 
        RankedOrders
    WHERE 
        rn = 1
)
SELECT 
    fs.total_orders,
    fs.total_revenue,
    fs.average_order_value,
    fs.first_order_date,
    fs.last_order_date,
    r.r_name AS region_name
FROM 
    FinalSummary fs
JOIN 
    nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c LIMIT 1)
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    fs.total_orders, 
    fs.total_revenue, 
    fs.average_order_value, 
    fs.first_order_date, 
    fs.last_order_date, 
    r.r_name;
