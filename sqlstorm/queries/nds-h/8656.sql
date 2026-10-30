WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderpriority,
        c.c_mktsegment,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS total_price_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
TopPriceOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderstatus,
        r.o_totalprice,
        r.o_orderpriority,
        r.c_mktsegment
    FROM 
        RankedOrders r
    WHERE 
        r.total_price_rank <= 10
),
OrderDetails AS (
    SELECT 
        t.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT p.p_partkey) AS unique_parts
    FROM 
        TopPriceOrders t
    JOIN 
        lineitem l ON t.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        t.o_orderkey
)
SELECT 
    t.o_orderkey,
    t.o_orderstatus,
    t.o_totalprice,
    t.o_orderpriority,
    od.total_revenue,
    od.unique_parts,
    CASE 
        WHEN od.total_revenue > 10000 THEN 'High Revenue'
        WHEN od.total_revenue BETWEEN 5000 AND 10000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM 
    TopPriceOrders t
JOIN 
    OrderDetails od ON t.o_orderkey = od.o_orderkey
ORDER BY 
    od.total_revenue DESC, t.o_orderkey;
