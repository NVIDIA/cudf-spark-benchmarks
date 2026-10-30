WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as price_rank,
        c.c_name,
        n.n_name AS customer_nation
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' 
        AND o.o_orderdate < DATE '1997-01-01'
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
        AND l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    COALESCE(l.net_revenue, 0) AS total_revenue,
    o.o_orderstatus,
    o.c_name,
    o.customer_nation,
    CASE 
        WHEN o.price_rank <= 5 THEN 'Top 5'
        ELSE 'Other'
    END AS rank_category
FROM 
    RankedOrders o
LEFT JOIN 
    FilteredLineItems l ON o.o_orderkey = l.l_orderkey
WHERE 
    o.o_orderstatus IN ('O', 'F') 
    AND (o.o_totalprice > 1000 OR l.net_revenue IS NULL)
ORDER BY 
    o.o_orderdate DESC, 
    total_revenue DESC
LIMIT 100;