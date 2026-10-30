
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_by_price,
        c.c_mktsegment
    FROM 
        orders o
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        CASE 
            WHEN p.p_retailprice IS NULL THEN 0 
            ELSE p.p_retailprice * 1.1 
        END AS adjusted_price
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 10 AND 30
),
MarketSegmentSummary AS (
    SELECT 
        r.r_name AS region,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        r.r_name
)
SELECT 
    m.region,
    m.order_count,
    m.total_revenue,
    COALESCE(s.total_cost, 0) AS supplier_cost,
    COUNT(DISTINCT r.o_orderkey) AS total_ranked_orders
FROM 
    MarketSegmentSummary m
LEFT JOIN 
    SupplierDetails s ON m.region = s.s_name 
LEFT JOIN 
    RankedOrders r ON r.o_orderkey = m.order_count 
WHERE 
    m.order_count > 5
GROUP BY 
    m.region,
    m.order_count,
    m.total_revenue,
    s.total_cost
ORDER BY 
    m.total_revenue DESC;
