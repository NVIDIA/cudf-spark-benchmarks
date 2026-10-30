WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= cast('1998-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
CustomerPurchases AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS customer_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        RANK() OVER (ORDER BY COUNT(DISTINCT s.s_suppkey) DESC) AS rank_number
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
    HAVING 
        COUNT(DISTINCT s.s_suppkey) > 0
)
SELECT 
    c.c_name AS customer_name,
    coalesce(r.total_revenue, 0) AS order_revenue,
    tp.n_name AS nation_name,
    tp.supplier_count,
    CASE 
        WHEN r.total_revenue IS NULL THEN 'No Orders in Last Year'
        WHEN r.total_revenue > 50000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_type
FROM 
    CustomerPurchases c
LEFT JOIN 
    RankedOrders r ON c.c_custkey = r.o_orderkey
LEFT JOIN 
    TopNations tp ON c.c_custkey = tp.n_nationkey
WHERE 
    tp.rank_number <= 10
ORDER BY 
    order_revenue DESC, customer_name;