
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (
            SELECT AVG(s2.s_acctbal) 
            FROM supplier s2 
            WHERE s2.s_nationkey = s.s_nationkey
        )
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
VendorPerformance AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(ps.ps_availqty) AS avg_avail_qty
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
TopRegions AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(n.n_nationkey) AS nation_count
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name
    HAVING 
        COUNT(n.n_nationkey) > 0
),
FinalSummary AS (
    SELECT 
        r.r_name,
        o.total_revenue AS cust_revenue,
        v.total_supply_cost,
        COALESCE(r.nation_count, 0) AS nation_count
    FROM 
        OrderSummary o
    JOIN 
        RankedSuppliers s ON o.o_custkey = s.s_suppkey
    JOIN 
        VendorPerformance v ON s.s_suppkey = v.ps_suppkey
    LEFT JOIN 
        TopRegions r ON s.s_nationkey = r.r_regionkey
)
SELECT 
    r_name,
    SUM(cust_revenue) AS total_revenue,
    SUM(total_supply_cost) AS total_supply_cost,
    AVG(nation_count) AS avg_nation_count
FROM 
    FinalSummary
GROUP BY 
    r_name
ORDER BY 
    total_revenue DESC, total_supply_cost DESC
LIMIT 10;
