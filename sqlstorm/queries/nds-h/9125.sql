WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopRevenueOrders AS (
    SELECT 
        r.o_orderkey,
        r.total_revenue,
        COUNT(DISTINCT s.s_suppkey) AS unique_suppliers
    FROM 
        RankedOrders r
    JOIN 
        lineitem l ON r.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        r.rank <= 10
    GROUP BY 
        r.o_orderkey, r.total_revenue
)

SELECT 
    t.o_orderkey,
    t.total_revenue,
    t.unique_suppliers,
    CASE 
        WHEN t.total_revenue > 100000 THEN 'High Revenue'
        WHEN t.total_revenue BETWEEN 50000 AND 100000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM 
    TopRevenueOrders t
ORDER BY 
    t.total_revenue DESC;
