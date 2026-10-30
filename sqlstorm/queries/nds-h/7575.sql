
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank,
        c.c_name,
        c.c_nationkey,
        s.s_name,
        s.s_nationkey
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
        o.o_orderdate >= DATE '1997-01-01'
        AND o.o_orderdate < DATE '1997-12-31'
),
FilteredRanked AS (
    SELECT 
        r.*,
        n.n_name,
        r.order_rank
    FROM 
        RankedOrders r
    JOIN 
        nation n ON r.c_nationkey = n.n_nationkey
    WHERE 
        r.order_rank <= 5
),
FinalResult AS (
    SELECT 
        fr.o_orderkey,
        fr.o_orderdate,
        fr.o_totalprice,
        fr.c_name AS customer_name,
        fr.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_suppkey) AS supplier_count
    FROM 
        FilteredRanked fr
    JOIN 
        lineitem l ON fr.o_orderkey = l.l_orderkey
    GROUP BY 
        fr.o_orderkey,
        fr.o_orderdate,
        fr.o_totalprice,
        fr.c_name,
        fr.n_name
)
SELECT 
    *,
    CASE 
        WHEN total_revenue > 10000 THEN 'High Value' 
        WHEN total_revenue BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS revenue_category
FROM 
    FinalResult
ORDER BY 
    o_orderdate DESC, total_revenue DESC;
