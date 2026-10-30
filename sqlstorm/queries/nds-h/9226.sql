WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        c.c_mktsegment,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
),
TopOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.o_totalprice,
        r.o_orderstatus,
        r.c_mktsegment
    FROM 
        RankedOrders r
    WHERE 
        r.order_rank <= 10
),
SupplierInfo AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_comment,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        TopOrders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey, s.s_name, s.s_acctbal, s.s_comment
),
FinalReport AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(si.total_revenue) AS total_revenue_by_nation
    FROM 
        SupplierInfo si
    JOIN 
        nation n ON si.ps_suppkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_name, r.r_name
)
SELECT 
    fr.nation_name,
    fr.region_name,
    fr.total_revenue_by_nation
FROM 
    FinalReport fr
ORDER BY 
    fr.total_revenue_by_nation DESC;