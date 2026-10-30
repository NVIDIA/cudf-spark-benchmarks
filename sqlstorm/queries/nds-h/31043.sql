
WITH  SupplyChain AS (
    SELECT 
        n.n_nationkey,
        n.n_name AS nation,
        r.r_name AS region,
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
), OrdersInfo AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS line_item_count,
        MAX(l.l_shipdate) AS last_ship_date
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey,
        o.o_custkey
), SupplierRevenue AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
), FinalReport AS (
    SELECT 
        s.nation,
        o.total_revenue,
        COALESCE(sr.total_supplycost, 0) AS total_supplycost,
        CASE 
            WHEN o.total_revenue > COALESCE(sr.total_supplycost, 0) THEN 'Profitable' 
            ELSE 'Non-Profitable' 
        END AS profitability_status
    FROM 
        SupplyChain s
    LEFT JOIN 
        OrdersInfo o ON s.s_suppkey = o.o_custkey
    LEFT JOIN 
        SupplierRevenue sr ON s.s_suppkey = sr.ps_partkey
)
SELECT 
    nation,
    total_revenue,
    total_supplycost,
    profitability_status
FROM 
    FinalReport
WHERE 
    total_revenue > 10000
ORDER BY 
    total_revenue DESC;
