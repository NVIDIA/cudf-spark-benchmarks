
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
TopOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.total_revenue,
        r.rank,
        c.c_name,
        s.s_name,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size
    FROM 
        RankedOrders r
    JOIN 
        orders o ON r.o_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        r.rank <= 10
)
SELECT 
    CAST(o_orderdate AS STRING) AS order_date,
    c_name AS customer_name,
    s_name AS supplier_name,
    SUM(total_revenue) AS revenue,
    COUNT(DISTINCT o_orderkey) AS number_of_orders
FROM 
    TopOrders
GROUP BY 
    o_orderdate, c_name, s_name
ORDER BY 
    revenue DESC
LIMIT 5;
